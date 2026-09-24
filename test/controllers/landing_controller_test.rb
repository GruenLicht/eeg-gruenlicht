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
end
