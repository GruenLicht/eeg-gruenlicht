require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "should get start" do
    get landing_start_url
    assert_response :success
  end

  test "should get mitmachen" do
    get landing_mitmachen_url
    assert_response :success
  end

  test "should get so_funktionierts" do
    get landing_so_funktionierts_url
    assert_response :success
  end

  test "should get ueber_uns" do
    get landing_ueber_uns_url
    assert_response :success
  end

  test "should get kontakt" do
    get landing_kontakt_url
    assert_response :success
  end

  test "should get zahlen" do
    get landing_zahlen_url
    assert_response :success
  end

  test "should get impressum" do
    get landing_impressum_url
    assert_response :success
  end

  test "should get datenschutz" do
    get landing_datenschutz_url
    assert_response :success
  end

  test "should get agb" do
    get landing_agb_url
    assert_response :success
  end
end
