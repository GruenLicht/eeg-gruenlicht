require "test_helper"

class BlogPostTest < ActiveSupport::TestCase
  test "all posts have valid frontmatter and render" do
    posts = BlogPost.all(include_drafts: true)

    assert posts.any?
    posts.each do |post|
      assert post.title.present?, "#{post.slug}: title fehlt"
      assert post.summary.present?, "#{post.slug}: summary fehlt"
      assert_kind_of Date, post.date
      assert post.html.present?
      assert_operator post.reading_minutes, :>=, 1
    end
  end

  test "slugs are unique" do
    slugs = BlogPost.all(include_drafts: true).map(&:slug)

    assert_equal slugs.uniq, slugs
  end

  test "posts are sorted newest first" do
    dates = BlogPost.all(include_drafts: true).map(&:date)

    assert_equal dates.sort.reverse, dates
  end

  test "drafts are hidden unless requested" do
    all = BlogPost.all(include_drafts: true)
    published = BlogPost.all(include_drafts: false)

    assert_equal all.reject(&:draft?), published
  end

  test "published posts contain no open placeholders" do
    BlogPost.all(include_drafts: true).reject(&:draft?).each do |post|
      assert_not_includes post.markdown, ".blog-todo", "#{post.slug}: offener Platzhalter in veröffentlichtem Beitrag"
    end
  end

  test "images referenced in posts exist" do
    BlogPost.all(include_drafts: true).each do |post|
      post.markdown.scan(%r{\]\((/blog-assets/[^)\s]+)\)}).flatten.each do |path|
        assert File.exist?(Rails.public_path.join(path.delete_prefix("/"))), "#{post.slug}: #{path} fehlt"
      end
    end
  end

  test "find raises for unknown slug" do
    assert_raises(ActiveRecord::RecordNotFound) { BlogPost.find("gibt-es-nicht") }
  end

  test "rejects invalid slug" do
    assert_raises(ArgumentError) do
      BlogPost.new(slug: "Mit Leerzeichen", meta: { "title" => "x", "date" => "2026-01-01" }, markdown: "")
    end
  end
end
