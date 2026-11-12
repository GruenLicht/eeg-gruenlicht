require "test_helper"

class ForumThemenTest < ActiveSupport::TestCase
  Thema = ForumThemen::Thema

  setup do
    @original_url = ENV["FORUM_URL"]
    ENV["FORUM_URL"] = "https://forum-beta.example.org/"
    ForumThemen.reset!
    @calls = 0
  end

  teardown do
    ENV["FORUM_URL"] = @original_url
    ForumThemen.reset!
  end

  def stub_fetcher(*results)
    queue = results.dup
    ForumThemen.fetcher = lambda do
      @calls += 1
      queue.shift
    end
  end

  test "ist ohne FORUM_URL deaktiviert und liefert keine Themen" do
    ENV["FORUM_URL"] = nil
    stub_fetcher([ Thema.new(titel: "x", url: "u", antworten: 0, geloest: false) ])

    refute ForumThemen.enabled?
    assert_equal [], ForumThemen.current
    assert_equal 0, @calls
  end

  test "baut die Links aus FORUM_URL ohne doppelten Schrägstrich" do
    assert_equal "https://forum-beta.example.org/c/willkommen-onboarding", ForumThemen.kategorie_url
    assert_equal "https://forum-beta.example.org/new-topic?category=willkommen-onboarding", ForumThemen.neues_thema_url
  end

  test "fragt das Forum innerhalb der TTL nur einmal ab" do
    stub_fetcher([ Thema.new(titel: "Frage", url: "u", antworten: 1, geloest: false) ])

    3.times { ForumThemen.current }

    assert_equal 1, @calls
  end

  test "behält nach einem Fehler den letzten guten Stand" do
    gut = [ Thema.new(titel: "Frage", url: "u", antworten: 1, geloest: true) ]
    stub_fetcher(gut, nil)

    assert_equal gut, ForumThemen.current
    ForumThemen.cache.delete(ForumThemen::CACHE_KEY)

    assert_equal gut, ForumThemen.current
  end

  test "findet die Kategorie-ID über den Slug" do
    body = { category_list: { categories: [
      { id: 4, slug: "allgemein" },
      { id: 7, slug: "willkommen-onboarding" }
    ] } }.to_json

    assert_equal 7, ForumThemen.parse_kategorie_id(body, "willkommen-onboarding")
    assert_nil ForumThemen.parse_kategorie_id(body, "gibt-es-nicht")
  end

  test "wandelt die Themenliste um und lässt angeheftete Themen aus" do
    body = { topic_list: { topics: [
      { id: 1, slug: "ueber-die-kategorie", title: "Über die Kategorie", posts_count: 1, pinned: true },
      { id: 12, slug: "freigabe-im-portal", title: "Wo finde ich die Freigabe?", posts_count: 3, has_accepted_answer: true },
      { id: 13, slug: "aufnahme", title: "Wie lange dauert die Aufnahme?", posts_count: 1 }
    ] } }.to_json

    themen = ForumThemen.parse_themen(body)

    assert_equal 2, themen.size
    assert_equal "Wo finde ich die Freigabe?", themen.first.titel
    assert_equal "https://forum-beta.example.org/t/freigabe-im-portal/12", themen.first.url
    assert_equal 2, themen.first.antworten
    assert themen.first.geloest
    assert_equal 0, themen.last.antworten
    refute themen.last.geloest
  end

  test "liefert nil bei unerwarteter Antwort" do
    assert_nil ForumThemen.parse_themen("kein json")
    assert_nil ForumThemen.parse_themen({ foo: 1 }.to_json)
  end
end
