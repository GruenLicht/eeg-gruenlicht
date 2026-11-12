require "test_helper"

class EegPreiseTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  def zeitraum(von, bis, bezug, einspeisung, source: "tariff", netto: bezug)
    {
      "valid_from" => von, "valid_to" => bis,
      "consumption_ct_per_kwh" => netto, "consumption_ct_per_kwh_gross" => bezug,
      "feed_in_ct_per_kwh" => einspeisung, "source" => source
    }
  end

  def gemeinschaft(rc:, name:, current:, upcoming: [], history: [], demo: false, fees: [], vat: 0)
    {
      "eeg_id" => "id-#{rc}", "rc_number" => rc, "name" => name, "display_name" => name, "demo" => demo,
      "vat" => { "rate_percent" => vat, "note" => "USt. (0 %, steuerbefreit gem. § 6 Abs. 1 Z 27 UStG)", "feed_in_note" => "Einspeisepreise netto" },
      "current" => current, "upcoming" => upcoming, "history" => history, "fees" => fees
    }
  end

  def antwort(*gemeinschaften)
    { "schema_version" => 1, "generated_at" => "2026-11-12T10:36:35+01:00", "communities" => gemeinschaften }
  end

  def bad_voeslau
    gemeinschaft(
      rc: "RC107602", name: "EEG Grünes Licht Bad Vöslau",
      current: zeitraum("2026-07-01", "2026-12-31", 11, 11),
      upcoming: [ zeitraum("2027-01-01", nil, 12, 0, source: "default") ],
      history: [ zeitraum("2026-01-01", "2026-06-30", 12, 12) ]
    )
  end

  def demo
    gemeinschaft(rc: "", name: "Demo Energiegemeinschaft", demo: true, vat: 20,
                 current: zeitraum("2024-01-01", nil, 10.2, 6, netto: 8.5))
  end

  setup do
    EegPreise.reset!
    @calls = 0
    travel_to Time.zone.local(2026, 11, 12, 12)
  end

  teardown do
    EegPreise.reset!
    travel_back
  end

  def stub_fetcher(*results)
    queue = results.dup
    EegPreise.fetcher = lambda do
      @calls += 1
      queue.shift
    end
  end

  test "liest Preise und blendet die Demo-EEG aus" do
    stub_fetcher(antwort(bad_voeslau, demo))

    stand = EegPreise.current

    assert stand.live?
    assert_equal [ "EEG Grünes Licht Bad Vöslau" ], stand.gemeinschaften.map(&:name)
    g = stand.gemeinschaften.first
    assert_equal "bad-voeslau", g.anker
    assert_equal 11, g.aktuell.bezug
    assert_equal 11, g.aktuell.einspeisung
    assert_equal Date.new(2026, 7, 1), g.aktuell.von
    assert_equal [ Date.new(2026, 1, 1) ], g.historie.map(&:von)
  end

  test "nach dem letzten Tarifeintrag gilt der letzte Tarif weiter, ein default wird nie gezeigt" do
    stub_fetcher(antwort(bad_voeslau))

    g = EegPreise.current.gemeinschaften.first

    assert_empty g.kuenftig
    assert_equal Date.new(2026, 7, 1), g.aktuell.von
    assert_nil g.aktuell.bis
    refute g.anzeige.any? { |z| z.einspeisung.zero? }
  end

  test "gleiche Preise hintereinander werden zusammengefasst" do
    eeg = bad_voeslau
    eeg["upcoming"] = [ zeitraum("2027-01-01", nil, 11, 11) ]
    stub_fetcher(antwort(eeg))

    g = EegPreise.current.gemeinschaften.first

    assert_empty g.kuenftig
    assert_equal Date.new(2026, 7, 1), g.aktuell.von
    assert_nil g.aktuell.bis
    assert_equal 2, g.anzeige.size
  end

  test "default zwischen zwei Tarifeinträgen ist ein echter Preis" do
    eeg = gemeinschaft(
      rc: "RC108113", name: "Flugfeld",
      current: zeitraum("2026-07-01", "2026-12-31", 11, 11),
      upcoming: [
        zeitraum("2027-01-01", "2027-03-31", 10, 10, source: "default"),
        zeitraum("2027-04-01", "2027-12-31", 9.3, 9.3),
        zeitraum("2028-01-01", nil, 0, 0, source: "default")
      ]
    )
    stub_fetcher(antwort(eeg))

    g = EegPreise.current.gemeinschaften.first

    assert_equal [ Date.new(2027, 1, 1), Date.new(2027, 4, 1) ], g.kuenftig.map(&:von)
    assert_equal BigDecimal("9.3"), g.kuenftig.last.bezug
    assert_nil g.kuenftig.last.bis
    assert_equal Date.new(2026, 12, 31), g.aktuell.bis
  end

  test "der aktuelle Zeitraum folgt dem heutigen Datum, auch bei einem älteren Stand" do
    stub_fetcher(antwort(bad_voeslau))

    travel_to Time.zone.local(2027, 1, 2, 12) do
      g = EegPreise.current.gemeinschaften.first

      assert_equal Date.new(2026, 7, 1), g.aktuell.von
      assert_equal 11, g.aktuell.bezug
      assert_equal [ Date.new(2026, 1, 1) ], g.historie.map(&:von)
    end
  end

  test "einheitlicher Preis nur, wenn alle Gemeinschaften gleich sind" do
    sooss = gemeinschaft(rc: "RC108354", name: "Sooß", current: zeitraum("2026-06-01", "2026-12-31", 11, 11))
    stub_fetcher(antwort(bad_voeslau, sooss))
    assert_equal 11, EegPreise.current.einheitlich.bezug

    EegPreise.reset!
    sooss["current"] = zeitraum("2026-06-01", "2026-12-31", 10, 11)
    stub_fetcher(antwort(bad_voeslau, sooss))
    stand = EegPreise.current
    assert_nil stand.einheitlich
    assert_equal [ 10, 11 ], stand.bezugspreise
    refute stand.gleicher_preis_fuer_bezug_und_einspeisung?
  end

  test "fragt die Schnittstelle innerhalb der TTL nur einmal ab" do
    stub_fetcher(antwort(bad_voeslau))

    3.times { EegPreise.current }

    assert_equal 1, @calls
  end

  test "behält den letzten Stand, wenn die Schnittstelle später ausfällt" do
    eeg = bad_voeslau
    eeg["current"] = zeitraum("2026-07-01", "2026-12-31", 9.3, 9.3)
    stub_fetcher(antwort(eeg), nil)

    EegPreise.current
    EegPreise.cache.delete(EegPreise::CACHE_KEY)
    stand = EegPreise.current

    assert_equal 2, @calls
    assert stand.live?
    assert_equal BigDecimal("9.3"), stand.gemeinschaften.first.aktuell.bezug
  end

  test "ohne erreichbare Schnittstelle gilt der Schnappschuss — nie eine leere Stelle" do
    stub_fetcher(nil, nil)

    stand = EegPreise.current

    assert_equal :snapshot, stand.quelle
    assert_equal 3, stand.gemeinschaften.size
    assert stand.gemeinschaften.all?(&:aktuell), "jede EEG braucht im Schnappschuss einen aktuellen Preis"
    refute stand.gemeinschaften.any? { |g| g.name.include?("Demo") }

    2.times { EegPreise.current }
    assert_equal 1, @calls, "nach einem Fehler nicht bei jedem Aufruf erneut fragen"
  end

  test "parse verwirft ungültige Antworten" do
    assert_nil EegPreise.parse("kein json")
    assert_nil EegPreise.parse("[]")
    assert_nil EegPreise.parse(antwort(bad_voeslau).merge("schema_version" => 2).to_json)
    assert_nil EegPreise.parse(antwort(demo).to_json)
    kaputt = bad_voeslau
    kaputt["current"]["consumption_ct_per_kwh_gross"] = "elf"
    assert_nil EegPreise.parse(antwort(kaputt).to_json)
    assert EegPreise.parse(antwort(bad_voeslau, demo).to_json)
  end

  test "der Schnappschuss im Repo ist gültig" do
    assert EegPreise.parse(File.read(EegPreise::SNAPSHOT_PATH))
  end

  test "in Tests wird ohne EEG_PREISE_URL keine Anfrage gestellt" do
    original = ENV["EEG_PREISE_URL"]
    ENV["EEG_PREISE_URL"] = nil
    assert_nil EegPreise.url
  ensure
    ENV["EEG_PREISE_URL"] = original
  end
end
