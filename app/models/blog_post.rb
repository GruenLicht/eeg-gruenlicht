require "yaml"
require "kramdown"

# Blog-Beiträge liegen als Markdown-Dateien mit YAML-Frontmatter in
# app/content/blog/<slug>.md. Der Dateiname ist zugleich die URL:
# app/content/blog/elwg-2026.md  ->  /blog/elwg-2026
#
# Frontmatter-Felder: title, date, author, category, summary,
# optional updated (Datum) und draft (true = nur lokal sichtbar).
class BlogPost
  CONTENT_DIR = Rails.root.join("app", "content", "blog")
  FRONTMATTER = /\A---\s*\n(.*?)\n---\s*\n/m
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  WORDS_PER_MINUTE = 200

  attr_reader :slug, :title, :date, :updated, :author, :category, :summary, :markdown

  class << self
    def all(include_drafts: show_drafts?)
      posts = load_all
      posts = posts.reject(&:draft?) unless include_drafts
      posts
    end

    def find(slug, include_drafts: show_drafts?)
      all(include_drafts: include_drafts).find { |post| post.slug == slug.to_s } ||
        raise(ActiveRecord::RecordNotFound, "Blog-Beitrag „#{slug}“ nicht gefunden")
    end

    # Entwürfe sind lokal und in Tests sichtbar, in Produktion nur mit
    # BLOG_SHOW_DRAFTS=1 (z.B. für eine Vorschau-Umgebung).
    def show_drafts?
      !Rails.env.production? || ENV["BLOG_SHOW_DRAFTS"] == "1"
    end

    # Solange BLOG_LISTED nicht "1" ist, ist der Blog in Produktion nur per
    # Direktlink erreichbar: kein Menüpunkt, kein Teaser auf der Startseite,
    # nicht in der Sitemap, Seiten mit noindex. Lokal und in Tests standardmäßig sichtbar.
    def listed?
      ENV.fetch("BLOG_LISTED") { Rails.env.production? ? "0" : "1" } == "1"
    end

    private

    def load_all
      return read_all if Rails.configuration.enable_reloading

      @all ||= read_all
    end

    def read_all
      Dir.glob(CONTENT_DIR.join("*.md"))
         .map { |path| from_file(path) }
         .sort_by { |post| [ post.date, post.slug ] }
         .reverse
         .freeze
    end

    def from_file(path)
      raw = File.read(path, encoding: "UTF-8")
      match = raw.match(FRONTMATTER) or raise ArgumentError, "#{path}: Frontmatter fehlt"
      meta = YAML.safe_load(match[1], permitted_classes: [ Date ]) || {}
      new(slug: File.basename(path, ".md"), meta: meta, markdown: match.post_match)
    end
  end

  def initialize(slug:, meta:, markdown:)
    raise ArgumentError, "Ungültiger Slug: #{slug}" unless slug.match?(SLUG_FORMAT)

    @slug     = slug
    @title    = meta.fetch("title")
    @date     = to_date(meta.fetch("date"))
    @updated  = meta["updated"] ? to_date(meta["updated"]) : nil
    @author   = meta["author"].presence || "EEG Grünes Licht"
    @category = meta["category"].presence
    @summary  = meta["summary"].to_s.strip
    @draft    = meta["draft"] == true
    @markdown = markdown
  end

  def draft?
    @draft
  end

  def to_param
    slug
  end

  def last_modified
    updated || date
  end

  def html
    @html ||= Kramdown::Document.new(
      markdown,
      input: "kramdown",
      auto_ids: true,
      header_offset: 0,
      smart_quotes: %w[sbquo lsquo bdquo ldquo]
    ).to_html.html_safe
  end

  def reading_minutes
    words = markdown.gsub(/<[^>]+>|\{:[^}]*\}/, " ").scan(/[[:alnum:]]+/).size
    [ (words / WORDS_PER_MINUTE.to_f).ceil, 1 ].max
  end

  private

  def to_date(value)
    value.is_a?(Date) ? value : Date.parse(value.to_s)
  end
end
