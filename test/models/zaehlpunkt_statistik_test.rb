require "test_helper"

class ZaehlpunktStatistikTest < ActiveSupport::TestCase
  Result = ZaehlpunktStatistik::Result

  setup do
    ZaehlpunktStatistik.reset!
    @calls = 0
  end

  teardown do
    ZaehlpunktStatistik.reset!
  end

  def stub_fetcher(*results)
    queue = results.dup
    ZaehlpunktStatistik.fetcher = lambda do
      @calls += 1
      queue.shift
    end
  end

  test "liefert die Zahlen der API" do
    stub_fetcher(Result.new(einspeiser: 66, verbraucher: 175))

    result = ZaehlpunktStatistik.current

    assert_equal 66, result.einspeiser
    assert_equal 175, result.verbraucher
  end

  test "fragt die API innerhalb der TTL nur einmal ab" do
    stub_fetcher(Result.new(einspeiser: 66, verbraucher: 175))

    3.times { ZaehlpunktStatistik.current }

    assert_equal 1, @calls
  end

  test "nutzt die Env-Werte, wenn die API nie erreichbar war" do
    stub_fetcher(nil)

    with_env("ANZAHL_EINSPEISER" => "65", "ANZAHL_VERBRAUCHER" => "171") do
      result = ZaehlpunktStatistik.current

      assert_equal 65, result.einspeiser
      assert_equal 171, result.verbraucher
    end
  end

  test "behält den letzten Stand, wenn die API später ausfällt" do
    stub_fetcher(Result.new(einspeiser: 66, verbraucher: 175), nil)

    ZaehlpunktStatistik.current
    ZaehlpunktStatistik.cache.delete(ZaehlpunktStatistik::CACHE_KEY)
    result = ZaehlpunktStatistik.current

    assert_equal 2, @calls
    assert_equal 66, result.einspeiser
    assert_equal 175, result.verbraucher
  end

  test "fragt nach einem Fehler nicht bei jedem Aufruf erneut" do
    stub_fetcher(nil, nil, nil)

    3.times { ZaehlpunktStatistik.current }

    assert_equal 1, @calls
  end

  test "parse liest eine gültige Antwort" do
    result = ZaehlpunktStatistik.parse('{"einspeiser":66,"verbraucher":175,"stand":"2026-10-17T15:13:02Z"}')

    assert_equal 66, result.einspeiser
    assert_equal 175, result.verbraucher
  end

  test "parse verwirft ungültige Antworten" do
    assert_nil ZaehlpunktStatistik.parse("kein json")
    assert_nil ZaehlpunktStatistik.parse('{"einspeiser":66}')
    assert_nil ZaehlpunktStatistik.parse('{"einspeiser":"x","verbraucher":175}')
    assert_nil ZaehlpunktStatistik.parse('{"einspeiser":-1,"verbraucher":175}')
    assert_nil ZaehlpunktStatistik.parse("[]")
  end

  test "ohne konfigurierte URL wird außerhalb von Produktion keine Anfrage gestellt" do
    with_env("GRUENLICHT_STATISTIK_URL" => nil) do
      assert_nil ZaehlpunktStatistik.url
    end
  end

  private

  def with_env(values)
    original = values.keys.to_h { |key| [key, ENV[key]] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end
end
