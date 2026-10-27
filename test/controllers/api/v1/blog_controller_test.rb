require "test_helper"

class Api::V1::BlogControllerTest < ActionDispatch::IntegrationTest
  test "index lists published, listed posts as JSON without browser user agent" do
    get "/api/v1/blog", headers: { "User-Agent" => "eeg-stack/1.0" }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.headers["Cache-Control"], "public"

    posts = response.parsed_body.fetch("posts")
    expected = BlogPost.all(include_drafts: false)
    assert_equal expected.map(&:slug), posts.map { |p| p["slug"] }
    assert posts.none? { |p| p.key?("markdown") }

    first = posts.first
    post = expected.first
    assert_equal post.title, first["title"]
    assert_equal post.date.iso8601, first["date"]
    assert_equal "https://eeg-gruenlicht.at/blog/#{post.slug}", first["url"]
    assert_equal "https://eeg-gruenlicht.at/api/v1/blog/#{post.slug}", first["api_url"]
  end

  test "index hides drafts and unlisted posts" do
    get "/api/v1/blog"

    slugs = response.parsed_body.fetch("posts").map { |p| p["slug"] }
    BlogPost.all(include_drafts: true, include_unlisted: true).each do |post|
      if post.draft? || post.unlisted?
        assert_not_includes slugs, post.slug
      else
        assert_includes slugs, post.slug
      end
    end
  end

  test "show returns portable markdown" do
    post = BlogPost.find("lastspitze-2027-portal-und-app")
    get "/api/v1/blog/#{post.slug}"

    assert_response :success
    body = response.parsed_body
    assert_equal post.slug, body["slug"]
    assert_equal post.title, body["title"]
    md = body.fetch("markdown")
    assert_includes md, "## Was ändert sich 2027?"
    assert_no_match(/\{:/, md)
    assert_no_match(/\]\(\/(?!\/)/, md)
    assert_includes md, "](https://eeg-gruenlicht.at/blog-assets/lastspitze/"
  end

  test "show serves an unlisted post by slug" do
    get "/api/v1/blog/eeg-assistent"

    assert_response :success
    assert_includes response.parsed_body.fetch("markdown"), "## Unsere eigene, sparsame KI"
  end

  test "show hides drafts and unknown slugs" do
    BlogPost.all(include_drafts: true).select(&:draft?).each do |post|
      get "/api/v1/blog/#{post.slug}"
      assert_response :not_found
    end

    get "/api/v1/blog/gibt-es-nicht"
    assert_response :not_found
    assert_equal({ "error" => "not_found" }, response.parsed_body)
  end
end
