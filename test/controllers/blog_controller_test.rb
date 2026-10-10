require "test_helper"

class BlogControllerTest < ActionDispatch::IntegrationTest
  def with_env(vars)
    previous = vars.keys.to_h { |key| [ key, ENV[key] ] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end

  BROWSER_HEADERS = {
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  }.freeze

  test "blog index lists posts" do
    get blog_url, headers: BROWSER_HEADERS

    assert_response :success
    BlogPost.all.each do |post|
      assert_includes response.body, blog_post_path(post)
    end
  end

  test "every post renders under its slug" do
    BlogPost.all.each do |post|
      get blog_post_url(post), headers: BROWSER_HEADERS

      assert_response :success, "expected 200 for #{post.slug}"
      assert_select "h1", text: post.title
      assert_select "link[rel=canonical][href=?]", "https://eeg-gruenlicht.at/blog/#{post.slug}"
    end
  end

  test "unknown slug returns 404" do
    get "/blog/gibt-es-nicht", headers: BROWSER_HEADERS

    assert_response :not_found
  end

  test "header navigation links to blog and no longer to Mitmachen" do
    get root_url, headers: BROWSER_HEADERS

    assert_select ".site-header-nav a.nav-blog[href=?]", blog_path
    assert_select ".site-header-nav a", text: "Mitmachen", count: 0
  end

  test "start page teases the three latest posts" do
    get root_url, headers: BROWSER_HEADERS

    assert_select "#neuigkeiten article", count: [ BlogPost.all.size, 3 ].min
    BlogPost.all.first(3).each do |post|
      assert_select "#neuigkeiten a[href=?]", blog_post_path(post)
    end
  end

  test "unlisted blog is reachable by link only" do
    with_env("BLOG_LISTED" => "0") do
      get root_url, headers: BROWSER_HEADERS
      assert_select ".site-header-nav a.nav-blog", count: 0
      assert_select ".mobile-menu-panel a.nav-blog", count: 0
      assert_select "#neuigkeiten article", count: 0

      get sitemap_url, headers: BROWSER_HEADERS
      assert_not_includes response.body, "/blog"

      get blog_url, headers: BROWSER_HEADERS
      assert_response :success
      assert_select "meta[name=robots][content=?]", "noindex,follow"

      post = BlogPost.all(include_drafts: false).first || BlogPost.all.first
      get blog_post_url(post), headers: BROWSER_HEADERS
      assert_response :success
      assert_select "meta[name=robots][content^=noindex]"
    end
  end

  test "sitemap lists only published posts" do
    get sitemap_url, headers: BROWSER_HEADERS

    assert_response :success
    assert_includes response.body, blog_path
    BlogPost.all(include_drafts: true).each do |post|
      if post.draft?
        assert_not_includes response.body, blog_post_path(post)
      else
        assert_includes response.body, blog_post_path(post)
      end
    end
  end
end
