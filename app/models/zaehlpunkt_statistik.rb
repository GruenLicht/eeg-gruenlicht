require "net/http"
require "json"

# Anzahl aktiver Zählpunkte (Einspeisung/Bezug) für die Startseite.
#
# Quelle ist der öffentliche Statistik-Endpoint der GrünLicht-API. Die API
# fragt die Datenbank höchstens alle 12 h ab; hier wird zusätzlich 1 h im
# Prozess zwischengespeichert, damit nicht jeder Seitenaufruf einen
# HTTP-Request auslöst. Ist die API nicht erreichbar, gilt der zuletzt
# gelesene Stand, ohne solchen die Env-Werte ANZAHL_EINSPEISER /
# ANZAHL_VERBRAUCHER. Nach einem Fehler folgt ein neuer Versuch frühestens
# nach 5 min.
class ZaehlpunktStatistik
  PRODUCTION_URL = "http://gruenlicht-api.eegabrechnung.svc.cluster.local/api/public/statistics".freeze
  CACHE_KEY = "zaehlpunkt_statistik".freeze
  LAST_GOOD_KEY = "zaehlpunkt_statistik/last_good".freeze
  TTL = 1.hour
  RETRY_AFTER_ERROR = 5.minutes
  TIMEOUT_SECONDS = 2

  Result = Struct.new(:einspeiser, :verbraucher, keyword_init: true)

  class << self
    attr_writer :fetcher

    def current
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
          result = cache.read(LAST_GOOD_KEY) || fallback
          cache.write(CACHE_KEY, result, expires_in: RETRY_AFTER_ERROR)
        end
        result
      end
    end

    def fetcher
      @fetcher ||= method(:fetch_from_api)
    end

    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end

    def reset!
      @cache = nil
      @fetcher = nil
    end

    def url
      ENV["GRUENLICHT_STATISTIK_URL"].presence || (Rails.env.production? ? PRODUCTION_URL : nil)
    end

    def parse(body)
      data = JSON.parse(body)
      einspeiser = Integer(data["einspeiser"])
      verbraucher = Integer(data["verbraucher"])
      return nil if einspeiser.negative? || verbraucher.negative?

      Result.new(einspeiser: einspeiser, verbraucher: verbraucher)
    rescue JSON::ParserError, TypeError, ArgumentError, NoMethodError
      nil
    end

    def fallback
      Result.new(
        einspeiser: ENV.fetch("ANZAHL_EINSPEISER", "3").to_i,
        verbraucher: ENV.fetch("ANZAHL_VERBRAUCHER", "5").to_i
      )
    end

    private

    def mutex
      @mutex ||= Mutex.new
    end

    def fetch_from_api
      return nil if url.blank?

      uri = URI(url)
      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: TIMEOUT_SECONDS,
        read_timeout: TIMEOUT_SECONDS
      ) { |http| http.get(uri.request_uri, "Accept" => "application/json") }

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[ZaehlpunktStatistik] API antwortet mit HTTP #{response.code}")
        return nil
      end

      result = parse(response.body)
      Rails.logger.warn("[ZaehlpunktStatistik] Unerwartete API-Antwort") unless result
      result
    rescue StandardError => e
      Rails.logger.warn("[ZaehlpunktStatistik] API nicht erreichbar: #{e.class}: #{e.message}")
      nil
    end
  end
end
