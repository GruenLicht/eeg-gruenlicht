require "net/http"
require "json"

# Energiepreise der drei Energiegemeinschaften, direkt aus der EEG-Abrechnung.
#
# Maßgeblich ist der Preis, mit dem die Abrechnung die Rechnungen erstellt. Die
# Website übernimmt ihn von der öffentlichen Schnittstelle
#
#   GET https://abrechnung.eeg-gruenlicht.at/api/v1/public/prices   (schema_version 1)
#
# und setzt ihn serverseitig ins HTML (Startseite, FAQ, /preise, Blog), damit
# auch der EEG-Assistent und Suchmaschinen den aktuellen Preis lesen.
#
# Zwischenspeicher: 10 min im Prozess. Ist die Schnittstelle nicht erreichbar,
# gilt der zuletzt gelesene Stand; ohne solchen der Schnappschuss in
# config/eeg_preise.json, der beim Bauen des Images neu geholt wird
# (rails eeg_preise:snapshot). Eine leere Stelle gibt es also nie. Nach einem
# Fehler folgt ein neuer Versuch frühestens nach 2 min.
#
# Anzeige-Regeln:
# - Ein "default" zwischen zwei Tarifeinträgen ist ein echter Preis.
# - Ein "default" NACH dem letzten Tarifeintrag wird nie als Preis gezeigt.
#   Entscheidung Christoph (12.11.2026): Die Website sagt dann nicht „noch nicht
#   festgelegt“, sondern der letzte Tarif gilt weiter („seit …“, ohne Ende).
# - Aufeinanderfolgende Zeiträume mit gleichen Preisen werden zusammengefasst
#   (z.B. Jahrestarif 2026 und 2027 mit je 11 ct -> „seit 1. Juli 2026“).
# Welcher Zeitraum aktuell ist, rechnen wir selbst aus dem heutigen Datum
# (Europe/Vienna) — so stimmt die Zuordnung auch mit einem älteren Stand.
class EegPreise
  DEFAULT_URL = "https://abrechnung.eeg-gruenlicht.at/api/v1/public/prices".freeze
  SNAPSHOT_PATH = Rails.root.join("config", "eeg_preise.json")
  SCHEMA_VERSION = 1
  CACHE_KEY = "eeg_preise".freeze
  LAST_GOOD_KEY = "eeg_preise/last_good".freeze
  TTL = 10.minutes
  RETRY_AFTER_ERROR = 2.minutes
  TIMEOUT_SECONDS = 3
  ZEITZONE = "Europe/Vienna".freeze

  # Bisherige Sprungmarken auf /preise beibehalten (#preise-bad-voeslau usw.).
  ANKER = {
    "RC107602" => "bad-voeslau",
    "RC108113" => "flugfeld",
    "RC108354" => "voeslau-sooss"
  }.freeze

  # Preise in ct/kWh. bezug = Bezugspreis brutto (für Haushalte maßgeblich),
  # bezug_netto = netto, einspeisung = Einspeisepreis.
  Zeitraum = Struct.new(:von, :bis, :bezug, :bezug_netto, :einspeisung, :quelle, :festgelegt, keyword_init: true) do
    def festgelegt?
      festgelegt
    end

    def gleicher_preis?(other)
      [ bezug, bezug_netto, einspeisung ] == [ other.bezug, other.bezug_netto, other.einspeisung ]
    end

    def gilt_am?(datum)
      von <= datum && (bis.nil? || datum <= bis)
    end
  end

  Gebuehr = Struct.new(:name, :betrag, :einheit, :je, :ust_prozent, keyword_init: true)

  Gemeinschaft = Struct.new(
    :rc_number, :eeg_id, :name, :ust_prozent, :ust_hinweis, :einspeisung_hinweis,
    :zeitraeume, :gebuehren, :heute, keyword_init: true
  ) do
    def anker
      ANKER.fetch(rc_number) { rc_number.to_s.downcase.presence || eeg_id }
    end

    # Zeiträume für die Anzeige, chronologisch: nur festgelegte Preise,
    # gleiche Preise zusammengefasst, der letzte Tarif ohne Ende.
    def anzeige
      @anzeige ||= begin
        liste = zeitraeume.select(&:festgelegt?).map(&:dup).each_with_object([]) do |z, ergebnis|
          vorher = ergebnis.last
          if vorher&.bis && vorher.bis + 1 == z.von && vorher.gleicher_preis?(z)
            vorher.bis = z.bis
          else
            ergebnis << z
          end
        end
        liste.last.bis = nil if liste.any?
        liste
      end
    end

    # Der heute gültige Zeitraum.
    def aktuell
      anzeige.find { |z| z.gilt_am?(heute) }
    end

    # Beschlossene künftige Preise, der nächste zuerst.
    def kuenftig
      anzeige.select { |z| z.von > heute }
    end

    # Vergangene Preise, der jüngste zuerst.
    def historie
      anzeige.select { |z| z.bis && z.bis < heute }.reverse
    end

    def ust_frei?
      ust_prozent.to_d.zero?
    end
  end

  Stand = Struct.new(:gemeinschaften, :erzeugt_am, :quelle, keyword_init: true) do
    def mit_aktuellem_preis
      gemeinschaften.select(&:aktuell)
    end

    # Gilt in allen Gemeinschaften derselbe aktuelle Preis? Dann dieser Zeitraum, sonst nil.
    def einheitlich
      aktuelle = gemeinschaften.map(&:aktuell)
      return nil if aktuelle.empty? || aktuelle.any?(&:nil?)
      return nil unless gemeinschaften.map(&:ust_prozent).uniq.size == 1

      aktuelle.first if aktuelle.map { |z| [ z.bezug, z.einspeisung ] }.uniq.size == 1
    end

    # Bezug und Einspeisung überall gleich hoch?
    def gleicher_preis_fuer_bezug_und_einspeisung?
      aktuelle = mit_aktuellem_preis.map(&:aktuell)
      aktuelle.any? && aktuelle.all? { |z| z.bezug == z.einspeisung }
    end

    def bezugspreise
      mit_aktuellem_preis.map { |g| g.aktuell.bezug }.uniq.sort
    end

    def einspeisepreise
      mit_aktuellem_preis.map { |g| g.aktuell.einspeisung }.uniq.sort
    end

    def alle_ust_frei?
      gemeinschaften.any? && gemeinschaften.all?(&:ust_frei?)
    end

    def live?
      quelle == :api
    end
  end

  class << self
    attr_writer :fetcher

    def current
      daten = cached_data
      build(daten[:json], quelle: daten[:quelle])
    end

    # Rohdaten (Hash) samt Herkunft, mit Zwischenspeicher und Rückfall.
    def cached_data
      cached = cache.read(CACHE_KEY)
      return cached if cached

      mutex.synchronize do
        cached = cache.read(CACHE_KEY)
        return cached if cached

        json = fetcher.call
        if json
          daten = { json: json, quelle: :api }
          cache.write(LAST_GOOD_KEY, daten)
          cache.write(CACHE_KEY, daten, expires_in: TTL)
        else
          daten = cache.read(LAST_GOOD_KEY) || { json: snapshot, quelle: :snapshot }
          cache.write(CACHE_KEY, daten, expires_in: RETRY_AFTER_ERROR)
        end
        daten
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

    # In Tests standardmäßig keine Anfrage (dann gilt der Schnappschuss).
    def url
      ENV["EEG_PREISE_URL"].presence || (Rails.env.test? ? nil : DEFAULT_URL)
    end

    # Prüft eine Antwort der Schnittstelle; gibt den Hash zurück oder nil.
    def parse(body)
      data = JSON.parse(body)
      return nil unless data.is_a?(Hash) && data["schema_version"] == SCHEMA_VERSION

      # Probeweise aufbauen: wirft bei fehlenden oder kaputten Feldern.
      return nil if build(data, quelle: :api).gemeinschaften.empty?

      data
    rescue JSON::ParserError, TypeError, ArgumentError, NoMethodError, KeyError
      nil
    end

    def snapshot
      JSON.parse(File.read(SNAPSHOT_PATH))
    end

    def heute
      Time.current.in_time_zone(ZEITZONE).to_date
    end

    def build(data, quelle:, datum: heute)
      gemeinschaften = Array(data.fetch("communities"))
                         .reject { |c| c["demo"] }
                         .map { |c| gemeinschaft(c, datum) }
                         .select { |g| g.anzeige.any? }
      erzeugt_am = data["generated_at"].presence && Time.zone.parse(data["generated_at"])&.in_time_zone(ZEITZONE)
      Stand.new(gemeinschaften: gemeinschaften, erzeugt_am: erzeugt_am, quelle: quelle)
    end

    # Holt die Schnittstelle und gibt den geprüften Hash zurück (oder nil).
    def fetch_json
      return nil if url.blank?

      uri = URI(url)
      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: TIMEOUT_SECONDS,
        read_timeout: TIMEOUT_SECONDS
      ) { |http| http.get(uri.request_uri, "Accept" => "application/json") }

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[EegPreise] Schnittstelle antwortet mit HTTP #{response.code}")
        return nil
      end

      json = parse(response.body)
      Rails.logger.warn("[EegPreise] Unerwartete Antwort der Schnittstelle") unless json
      json
    rescue StandardError => e
      Rails.logger.warn("[EegPreise] Schnittstelle nicht erreichbar: #{e.class}: #{e.message}")
      nil
    end

    private

    def mutex
      @mutex ||= Mutex.new
    end

    def fetch_from_api
      fetch_json
    end

    def gemeinschaft(c, datum)
      vat = c.fetch("vat")
      Gemeinschaft.new(
        rc_number: c["rc_number"].to_s,
        eeg_id: c["eeg_id"].to_s,
        name: c["display_name"].presence || c.fetch("name"),
        ust_prozent: zahl(vat.fetch("rate_percent")),
        ust_hinweis: vat["note"].to_s,
        einspeisung_hinweis: vat["feed_in_note"].to_s,
        zeitraeume: zeitraeume(c),
        gebuehren: Array(c["fees"]).map { |f| gebuehr(f) },
        heute: datum
      )
    end

    # Alle Zeiträume chronologisch, mit der Anzeige-Regel für "default".
    def zeitraeume(c)
      roh = Array(c["history"]) + [ c["current"] ].compact + Array(c["upcoming"])
      sortiert = roh.map { |z| zeitraum(z) }.uniq { |z| z.von }.sort_by(&:von)
      letzter_tarif = sortiert.rindex { |z| z.quelle == "tariff" }
      sortiert.each_with_index do |z, i|
        z.festgelegt = z.quelle != "default" || (!letzter_tarif.nil? && i < letzter_tarif)
      end
      sortiert
    end

    def zeitraum(z)
      Zeitraum.new(
        von: Date.iso8601(z.fetch("valid_from")),
        bis: z["valid_to"].present? ? Date.iso8601(z["valid_to"]) : nil,
        bezug: zahl(z.fetch("consumption_ct_per_kwh_gross")),
        bezug_netto: zahl(z.fetch("consumption_ct_per_kwh")),
        einspeisung: zahl(z.fetch("feed_in_ct_per_kwh")),
        quelle: z["source"].to_s
      )
    end

    def gebuehr(f)
      Gebuehr.new(
        name: f.fetch("name").to_s,
        betrag: zahl(f.fetch("amount")),
        einheit: f["unit"].to_s,
        je: f["per"].to_s,
        ust_prozent: f["vat_rate_percent"].nil? ? nil : zahl(f["vat_rate_percent"])
      )
    end

    def zahl(wert)
      raise ArgumentError, "keine Zahl: #{wert.inspect}" unless wert.is_a?(Numeric)

      BigDecimal(wert.to_s)
    end
  end
end
