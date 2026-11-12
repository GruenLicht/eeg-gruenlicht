require "test_helper"

# Preisangaben der Website kommen aus der EEG-Abrechnung (EegPreise) und stehen im
# ausgelieferten HTML — nicht erst per JavaScript.
class PreiseTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  BROWSER_HEADERS = {
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  }.freeze

  setup do
    EegPreise.reset!
    travel_to Time.zone.local(2026, 11, 12, 12)
  end

  teardown do
    EegPreise.reset!
    travel_back
  end

  # Schnappschuss mit geändertem Preis als Antwort der Schnittstelle.
  def stub_preis(bezug, einspeisung = bezug, upcoming: nil)
    data = EegPreise.snapshot
    data["communities"].each do |c|
      next if c["demo"]

      c["current"].merge!("consumption_ct_per_kwh" => bezug, "consumption_ct_per_kwh_gross" => bezug, "feed_in_ct_per_kwh" => einspeisung)
      c["upcoming"] = upcoming if upcoming
    end
    EegPreise.fetcher = -> { data }
  end

  def text(html)
    Nokogiri::HTML(html).text.squish
  end

  test "/preise zeigt aktuelle, offene und bisherige Preise je EEG ohne Demo-EEG" do
    get preise_path, headers: BROWSER_HEADERS

    assert_response :success
    body = text(response.body)
    %w[bad-voeslau flugfeld voeslau-sooss].each do |anker|
      assert_includes response.body, %(id="preise-#{anker}")
    end
    assert_includes body, "Aktueller Preis, gültig 1. Juli bis 31. Dezember 2026"
    assert_includes body, "Aktueller Preis, gültig 1. Juni bis 31. Dezember 2026"
    assert_includes body, "1. Jänner bis 30. Juni 2026 12 ct/kWh USt-frei 12 ct/kWh netto Historisch"
    assert_includes body, "1. Mai bis 30. Juni 2026 12 ct/kWh USt-frei 12 ct/kWh netto Historisch"
    assert_includes body, "ab 1. Jänner 2027 noch nicht festgelegt"
    assert_includes body, "steuerbefreit gem. § 6 Abs. 1 Z 27 UStG"
    refute_includes body, "Demo"
    refute_includes body, "Messstellengebühr"
  end

  test "Preisänderung in der Abrechnung erscheint auf allen Seiten" do
    stub_preis(9.3)

    [ root_path, preise_path, blog_post_path("eeg-assistent-mitgliederportal") ].each do |pfad|
      get pfad, headers: BROWSER_HEADERS
      assert_response :success
      assert_includes response.body, "9,3 ct/kWh", "kein Preis aus der Schnittstelle auf #{pfad}"
      refute_match(/\b11 ct\/kWh/, response.body, "fester Preis auf #{pfad}")
    end
  end

  test "Startseite und FAQ nennen den Preis aus der Abrechnung" do
    get root_path, headers: BROWSER_HEADERS

    assert_response :success
    body = text(response.body)
    assert_includes response.body, %(<meta name="description" content="EEG Grünes Licht Bad Vöslau: regionale Energiegemeinschaft mit 11 ct/kWh USt-frei)
    assert_includes body, "11 ct/kWh USt-frei (für Einspeiser/Abnehmer gleich)"
    assert_includes body, "derselbe Energiepreis: 11 ct/kWh USt-frei"
    assert_includes body, "Mit diesem Preis erstellt die Abrechnung der EEG die Rechnungen. Der Preis ab 1. Jänner 2027 ist noch nicht festgelegt."
    assert_includes body, "Regelt die Teilnahme mit Ihrem Verbrauchszählpunkt: der jeweils gültige Energiepreis (derzeit 11 ct/kWh USt-frei)"
    assert_includes body, "vergütet ihn mit dem jeweils gültigen Einspeisepreis (derzeit 11 ct/kWh)"
    assert_includes response.body, %(id="faq-gesamtkosten")
    assert_includes body, "Was kostet mich eine kWh aus der Energiegemeinschaft insgesamt?"
    assert_includes body, "20 × 11 ct = 2,20 €"
    assert_includes body, "2026 um 28 %, nach dem Tarifentwurf für 2027 um 22 %"
  end

  test "unterschiedliche Preise für Bezug und Einspeisung werden nicht als gleich ausgegeben" do
    stub_preis(12, 10)

    get root_path, headers: BROWSER_HEADERS

    body = text(response.body)
    refute_includes body, "für Einspeiser/Abnehmer gleich"
    refute_includes body, "derselbe Energiepreis"
    assert_includes body, "Bezugspreis von 12 ct/kWh USt-frei und ein Einspeisepreis von 10 ct/kWh"
    assert_includes body, "20 × 12 ct = 2,40 €"
  end

  test "beschlossene künftige Preise stehen auf /preise und in der FAQ" do
    stub_preis(11, upcoming: [
      { "valid_from" => "2027-01-01", "valid_to" => "2027-12-31", "consumption_ct_per_kwh" => 10.5,
        "consumption_ct_per_kwh_gross" => 10.5, "feed_in_ct_per_kwh" => 10.5, "source" => "tariff" },
      { "valid_from" => "2028-01-01", "valid_to" => nil, "consumption_ct_per_kwh" => 0,
        "consumption_ct_per_kwh_gross" => 0, "feed_in_ct_per_kwh" => 0, "source" => "default" }
    ])

    get preise_path, headers: BROWSER_HEADERS
    body = text(response.body)
    assert_includes body, "1. Jänner bis 31. Dezember 2027 10,5 ct/kWh USt-frei 10,5 ct/kWh netto Beschlossen"
    assert_includes body, "ab 1. Jänner 2028 noch nicht festgelegt"

    get root_path, headers: BROWSER_HEADERS
    assert_includes text(response.body), "Bereits beschlossen: ab 1. Jänner 2027 in der EEG Grünes Licht Bad Vöslau: Bezug 10,5 ct/kWh"
  end

  test "ohne Antwort der Schnittstelle bleibt der letzte Stand stehen" do
    EegPreise.fetcher = -> { nil }

    get preise_path, headers: BROWSER_HEADERS
    assert_response :success
    assert_includes text(response.body), "Bezugspreis 11 ct/kWh USt-frei"

    get root_path, headers: BROWSER_HEADERS
    assert_response :success
    assert_includes text(response.body), "derselbe Energiepreis: 11 ct/kWh USt-frei"
  end

  test "ohne festgelegten Preis steht ein Hinweis statt einer leeren Stelle" do
    EegPreise.fetcher = -> { nil }

    travel_to Time.zone.local(2027, 1, 5, 12) do
      get preise_path, headers: BROWSER_HEADERS
      assert_includes text(response.body), "Der Preis ab 1. Jänner 2027 ist noch nicht festgelegt."

      get root_path, headers: BROWSER_HEADERS
      assert_response :success
      assert_includes text(response.body), "noch nicht festgelegt"
    end
  end

  test "/preise steht in der Sitemap" do
    get sitemap_path(format: :xml)

    assert_response :success
    assert_includes response.body, "/preise</loc>"
  end

  test "keine festen Preise im Quelltext der Seiten" do
    dateien = Dir[Rails.root.join("app/views/**/*.erb")] + Dir[Rails.root.join("app/helpers/*.rb")]
    dateien.each do |datei|
      inhalt = File.readlines(datei).reject { |zeile| zeile.strip.start_with?("#") }.join
      refute_match(/\d+(,\d+)?\s*(ct\/kWh|Cent je kWh)/, inhalt, "fester Preis in #{datei}")
    end
  end
end
