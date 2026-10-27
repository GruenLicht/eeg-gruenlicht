# Blog-API (JSON) für andere Programme, z.B. den EEG-Assistenten (eeg-stack), damit sie
# die Beiträge nicht aus dem HTML kratzen müssen.
#
#   GET /api/v1/blog          Liste der veröffentlichten Beiträge (ohne Text), neueste zuerst
#   GET /api/v1/blog/:slug    ein Beitrag samt Text in Markdown
#
# Die Liste enthält dieselben Beiträge wie die Blog-Übersicht: keine Entwürfe und keine
# nicht gelisteten Beiträge (unlisted: true). Einzeln abrufbar ist ein nicht gelisteter
# Beitrag wie im Browser über seinen Slug; Entwürfe sind in Produktion nie abrufbar.
#
# ActionController::API statt ApplicationController: keine Browser-Prüfung (allow_browser
# würde Programme ohne Browser-User-Agent mit 406 abweisen), keine Sessions, kein CSRF.
module Api
  module V1
    class BlogController < ActionController::API
      CACHE_SECONDS = 300

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "not_found" }, status: :not_found
      end

      def index
        posts = BlogPost.all(include_drafts: false)
        expires_in CACHE_SECONDS, public: true
        render json: { posts: posts.map { |post| summary_json(post) } }
      end

      def show
        post = BlogPost.find(params[:slug], include_drafts: false)
        expires_in CACHE_SECONDS, public: true
        render json: summary_json(post).merge(
          markdown: post.portable_markdown(site_url)
        )
      end

      private

      # Wie SeoHelper#site_url — absolute Links zeigen immer auf die öffentliche Adresse,
      # nicht auf den internen Host hinter dem Ingress.
      def site_url
        ENV["SITE_URL"].presence || "https://eeg-gruenlicht.at"
      end

      def summary_json(post)
        {
          slug: post.slug,
          title: post.title,
          summary: post.summary,
          author: post.author,
          category: post.category,
          date: post.date.iso8601,
          updated: post.updated&.iso8601,
          reading_minutes: post.reading_minutes,
          url: URI.join(site_url, "/blog/#{post.slug}").to_s,
          api_url: URI.join(site_url, "/api/v1/blog/#{post.slug}").to_s
        }
      end
    end
  end
end
