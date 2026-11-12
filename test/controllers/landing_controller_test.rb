require "test_helper"

class FailingContactDelivery
  def initialize(_settings = {}); end

  def deliver!(_mail)
    raise Net::SMTPAuthenticationError.new("535 5.7.8 Error: authentication failed")
  end
end

ActionMailer::Base.add_delivery_method :failing_contact, FailingContactDelivery

class LandingControllerTest < ActionDispatch::IntegrationTest
  BROWSER_HEADERS = {
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  }.freeze

  TURBO_HEADERS = BROWSER_HEADERS.merge(
    "Accept" => "text/vnd.turbo-stream.html, text/html"
  ).freeze

  VALID_PARAMS = {
    contact_request: {
      name: "Erika Muster",
      email: "erika@example.org",
      message: "Ich interessiere mich für die EEG.",
      privacy_consent: "1",
      honeypot: ""
    }
  }.freeze

  setup do
    ActionMailer::Base.deliveries.clear
    @original_delivery_method = ActionMailer::Base.delivery_method
  end

  teardown do
    ActionMailer::Base.delivery_method = @original_delivery_method
  end

  test "start page renders" do
    get root_url, headers: BROWSER_HEADERS
    assert_response :success
  end

  test "start page offers membership only in EEG Bad Vöslau" do
    get root_url, headers: BROWSER_HEADERS

    assert_response :success
    assert_includes response.body, "Umspannwerk Baden"
    assert_includes response.body, "https://abrechnung.eeg-gruenlicht.at/onboarding/437a846f-a56f-4f35-86b0-0ff31041b915"
    assert_includes response.body, %(id="beitrittsformular")
    assert_includes response.body, "00BA21, 00BA22 oder 00BA23"
    refute_includes response.body, "cb81cc8e-a2a3-4660-b4cc-067c15d9b277"
    refute_includes response.body, "e10c2146-c551-4e73-8515-573c30be6c7e"
  end

  test "start page hides the forum tab without FORUM_URL" do
    original = ENV["FORUM_URL"]
    ENV["FORUM_URL"] = nil
    ForumThemen.reset!

    get root_url, headers: BROWSER_HEADERS

    assert_response :success
    refute_includes response.body, %(id="service-tab-forum")
  ensure
    ENV["FORUM_URL"] = original
    ForumThemen.reset!
  end

  test "start page shows the forum tab with the latest topics" do
    original = ENV["FORUM_URL"]
    ENV["FORUM_URL"] = "https://forum-beta.example.org"
    ForumThemen.reset!
    ForumThemen.fetcher = -> {
      [ ForumThemen::Thema.new(titel: "Wo finde ich die Freigabe?", url: "https://forum-beta.example.org/t/freigabe/12", antworten: 2, geloest: true) ]
    }

    get root_url, headers: BROWSER_HEADERS

    assert_response :success
    assert_includes response.body, %(id="service-tab-forum")
    assert_includes response.body, "Wo finde ich die Freigabe?"
    assert_includes response.body, "https://forum-beta.example.org/new-topic?category=willkommen-onboarding"
  ensure
    ENV["FORUM_URL"] = original
    ForumThemen.reset!
  end

  test "static pages render" do
    [ preise_url, unterstuetzer_url, impressum_url, datenschutz_url, app_datenloeschung_url ].each do |url|
      get url, headers: BROWSER_HEADERS
      assert_response :success, "expected 200 for #{url}"
    end
  end

  test "invalid contact request shows validation errors and sends no mail" do
    post kontakt_url, params: { contact_request: { name: "", email: "", message: "" } }, headers: TURBO_HEADERS

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "Bitte prüfen Sie Ihre Eingaben."
    assert_empty ActionMailer::Base.deliveries
  end

  test "valid contact request sends mail with reply-to of the sender" do
    post kontakt_url, params: VALID_PARAMS, headers: TURBO_HEADERS

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "Ihre Nachricht wurde erfolgreich gesendet."

    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "erika@example.org" ], mail.reply_to
    assert_includes mail[:reply_to].to_s, "Erika Muster"
    assert_equal "[EEG Website Kontakt] Erika Muster", mail.subject
    assert_includes mail.text_part.decoded, "Ich interessiere mich für die EEG."
  end

  test "invalid sender address is not used as reply-to" do
    params = VALID_PARAMS.deep_dup
    params[:contact_request][:email] = "keine-adresse"

    post kontakt_url, params: params, headers: TURBO_HEADERS

    assert_response :success
    mail = ActionMailer::Base.deliveries.last
    assert_empty Array(mail.reply_to)
  end

  test "delivery failure shows a friendly error inside the frame" do
    ActionMailer::Base.delivery_method = :failing_contact

    post kontakt_url, params: VALID_PARAMS, headers: TURBO_HEADERS

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, %(<turbo-frame id="kontaktformular">)
    assert_includes response.body, "Ihre Nachricht konnte leider nicht gesendet werden."
    assert_includes response.body, "office@eeg-gruenlicht.at"
    assert_includes response.body, "Ich interessiere mich für die EEG."
  end

  test "honeypot submissions are silently accepted without mail" do
    params = VALID_PARAMS.deep_dup
    params[:contact_request][:honeypot] = "spam"

    post kontakt_url, params: params, headers: TURBO_HEADERS

    assert_response :success
    assert_includes response.body, "Ihre Nachricht wurde übermittelt."
    assert_empty ActionMailer::Base.deliveries
  end

  test "start page shows meter point counts from the API" do
    ZaehlpunktStatistik.reset!
    ZaehlpunktStatistik.fetcher = -> { ZaehlpunktStatistik::Result.new(einspeiser: 66, verbraucher: 175) }

    get root_path, headers: BROWSER_HEADERS

    assert_response :success
    assert_includes response.body, "66 Einspeiser · 175 Verbraucher"
  ensure
    ZaehlpunktStatistik.reset!
  end
end
