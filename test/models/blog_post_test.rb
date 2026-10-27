require "test_helper"

class BlogPostTest < ActiveSupport::TestCase
  test "all posts have valid frontmatter and render" do
    posts = BlogPost.all(include_drafts: true, include_unlisted: true)

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
    slugs = BlogPost.all(include_drafts: true, include_unlisted: true).map(&:slug)

    assert_equal slugs.uniq, slugs
  end

  test "posts are sorted newest first" do
    dates = BlogPost.all(include_drafts: true, include_unlisted: true).map(&:date)

    assert_equal dates.sort.reverse, dates
  end

  test "drafts are hidden unless requested" do
    all = BlogPost.all(include_drafts: true, include_unlisted: true)
    published = BlogPost.all(include_drafts: false, include_unlisted: true)

    assert_equal all.reject(&:draft?), published
  end

  test "published posts contain no open placeholders" do
    BlogPost.all(include_drafts: true, include_unlisted: true).reject(&:draft?).each do |post|
      assert_not_includes post.markdown, ".blog-todo", "#{post.slug}: offener Platzhalter in veröffentlichtem Beitrag"
    end
  end

  test "images referenced in posts exist" do
    BlogPost.all(include_drafts: true, include_unlisted: true).each do |post|
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
  def post_with(markdown)
    BlogPost.new(slug: "test", meta: { "title" => "T", "date" => "2026-10-27" }, markdown: markdown)
  end

  test "portable markdown drops kramdown attributes and todo paragraphs, makes links absolute" do
    md = <<~MD
      Einleitung mit [Link](/blog/abc) und [extern](https://example.at/x).

      Platzhalter, der raus muss.
      {: .blog-todo}

      **Wichtig.** Infobox.
      {: .blog-info}

      [![Bild](/blog-assets/a.png){: loading="lazy" .blog-medium}](/blog-assets/a.png){: target="_blank" rel="noopener"}

      Kontakt: [Schreiben Sie uns](/#kontakt), Protokoll-relativ bleibt [so](//cdn.example.at/x).
    MD

    out = post_with(md).portable_markdown("https://eeg-gruenlicht.at/")

    assert_equal <<~EXPECTED, out
      Einleitung mit [Link](https://eeg-gruenlicht.at/blog/abc) und [extern](https://example.at/x).

      **Wichtig.** Infobox.

      [![Bild](https://eeg-gruenlicht.at/blog-assets/a.png)](https://eeg-gruenlicht.at/blog-assets/a.png)

      Kontakt: [Schreiben Sie uns](https://eeg-gruenlicht.at/#kontakt), Protokoll-relativ bleibt [so](//cdn.example.at/x).
    EXPECTED
  end

  test "unlisted posts are found by slug but not listed" do
    assert BlogPost.find("eeg-assistent").unlisted?
    assert_not_includes BlogPost.all.map(&:slug), "eeg-assistent"
    assert_not_includes BlogPost.all(include_drafts: true).map(&:slug), "eeg-assistent"
    assert_includes BlogPost.all(include_unlisted: true).map(&:slug), "eeg-assistent"
  end
end
