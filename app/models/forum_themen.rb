require "net/http"
require "json"

# Neueste Themen aus der öffentlichen Forum-Kategorie für den Reiter „Forum"
# im Servicebereich der Startseite.
#
# Aktiv nur, wenn FORUM_URL gesetzt ist (z. B. https://forum-beta.eeg-gruenlicht.at);
# ohne FORUM_URL wird der Reiter gar nicht angezeigt. Die Kategorie wird über
# ihren Slug gefunden (FORUM_KATEGORIE, Standard "willkommen-onboarding").
#
# Die Website holt die Liste serverseitig über die JSON-API von Discourse und
# speichert sie 10 min im Prozess zwischen — der Browser lädt also kein Skript
# und keine Cookies vom Forum. Ist das Forum nicht erreichbar, gilt der zuletzt
# gelesene Stand, ohne solchen eine leere Liste; ein neuer Versuch folgt
# frühestens nach 2 min.
class ForumThemen
  DEFAULT_KATEGORIE = "willkommen-onboarding".freeze
  CACHE_KEY = "forum_themen".freeze
  LAST_GOOD_KEY = "forum_themen/last_good".freeze
  TTL = 10.minutes
  RETRY_AFTER_ERROR = 2.minutes
  TIMEOUT_SECONDS = 2
  LIMIT = 5

  Thema = Struct.new(:titel, :url, :antworten, :geloest, keyword_init: true)

  class << self
    attr_writer :fetcher

    def enabled?
      base_url.present?
    end

    def base_url
      ENV["FORUM_URL"].presence&.chomp("/")
    end

    # Interne Adresse für die API-Abfrage (optional, z. B. der Cluster-Service);
    # Links für Besucher zeigen immer auf FORUM_URL.
    def api_url
      ENV["FORUM_API_URL"].presence&.chomp("/") || base_url
    end

    def kategorie
      ENV["FORUM_KATEGORIE"].presence || DEFAULT_KATEGORIE
    end

    def kategorie_url
      "#{base_url}/c/#{kategorie}"
    end

    def neues_thema_url
      "#{base_url}/new-topic?category=#{kategorie}"
    end

    def current
      return [] unless enabled?

      cached = cache.read(CACHE_KEY)
      return cached if cached

      mutex.synchronize do
        cached = cache.read(CACHE_KEY)
        return cached if cached

        result = fetcher.call
        if result
          cache.write(LAST_GOOD_KEY, result)
          cache.write(CACHE_KEY, result, expires_in: TTL)
        else
          result = cache.read(LAST_GOOD_KEY) || []
          cache.write(CACHE_KEY, result, expires_in: RETRY_AFTER_ERROR)
        end
        result
      end
    end

    def fetcher
      @fetcher ||= method(:fetch_from_forum)
    end

    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end

    def reset!
      @cache = nil
      @fetcher = nil
    end

    # Liefert die Kategorie-ID zum Slug aus /categories.json.
    def parse_kategorie_id(body, slug)
      categories = JSON.parse(body).dig("category_list", "categories") || []
      category = categories.find { |c| c["slug"] == slug }
      category && Integer(category["id"])
    rescue JSON::ParserError, TypeError, ArgumentError
      nil
    end

    # Wandelt die Themenliste aus /c/<slug>/<id>.json in Thema-Objekte um.
    # Angeheftete Themen (z. B. „Über die Kategorie …") werden ausgelassen.
    def parse_themen(body)
      topics = JSON.parse(body).dig("topic_list", "topics")
      return nil unless topics.is_a?(Array)

      topics
        .reject { |t| t["pinned"] || t["pinned_globally"] || t["visible"] == false }
        .first(LIMIT)
        .map do |t|
          Thema.new(
            titel: t["title"].to_s,
            url: "#{base_url}/t/#{t['slug']}/#{t['id']}",
            antworten: [ t["posts_count"].to_i - 1, 0 ].max,
            geloest: t["has_accepted_answer"] == true
          )
        end
    rescue JSON::ParserError, TypeError, NoMethodError
      nil
    end

    private

    def mutex
      @mutex ||= Mutex.new
    end

    def fetch_from_forum
      kategorie_id = parse_kategorie_id(get("/categories.json"), kategorie)
      unless kategorie_id
        Rails.logger.warn("[ForumThemen] Kategorie #{kategorie.inspect} nicht gefunden")
        return nil
      end

      themen = parse_themen(get("/c/#{kategorie}/#{kategorie_id}.json"))
      Rails.logger.warn("[ForumThemen] Unerwartete Antwort des Forums") unless themen
      themen
    rescue StandardError => e
      Rails.logger.warn("[ForumThemen] Forum nicht erreichbar: #{e.class}: #{e.message}")
      nil
    end

    def get(path)
      uri = URI("#{api_url}#{path}")
      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: TIMEOUT_SECONDS,
        read_timeout: TIMEOUT_SECONDS
      ) { |http| http.get(uri.request_uri, "Accept" => "application/json") }

      raise "HTTP #{response.code} für #{path}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end
  end
end
