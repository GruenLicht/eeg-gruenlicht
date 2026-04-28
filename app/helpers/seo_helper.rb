module SeoHelper
  def site_name
    "EEG Grünes Licht Bad Vöslau"
  end

  def site_url
    ENV["SITE_URL"].presence || "https://eeg-gruenlicht.at"
  end

  def seo_title
    page_title = content_for?(:title) ? content_for(:title) : nil
    return site_name if page_title.blank?

    "#{page_title} | #{site_name}"
  end

  def seo_description
    content_for?(:meta_description) ? content_for(:meta_description) : default_meta_description
  end

  def default_meta_description
    "Regionale Energiegemeinschaft in Bad Vöslau: 10 ct/kWh netto, reduzierte Netzentgelte beim Bezug innerhalb der EEG, keine Mitgliedsgebühr und monatliche Abrechnung."
  end

  def canonical_url
    canonical_path =
      if content_for?(:canonical_path)
        content_for(:canonical_path)
      elsif request&.fullpath.present?
        request.fullpath
      else
        "/"
      end

    URI.join(site_url, canonical_path).to_s
  end

  def seo_image_url
    URI.join(site_url, ActionController::Base.helpers.asset_path("apple-touch-icon.png")).to_s
  end

  def organization_json_ld
    data = {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => site_name,
      "url" => site_url,
      "logo" => seo_image_url,
      "email" => "office@eeg-gruenlicht.at",
      "address" => {
        "@type" => "PostalAddress",
        "streetAddress" => "Michael Scherz-Straße 14",
        "postalCode" => "2540",
        "addressLocality" => "Bad Vöslau",
        "addressCountry" => "AT"
      },
      "areaServed" => {
        "@type" => "City",
        "name" => "Bad Vöslau"
      }
    }

    JSON.pretty_generate(data)
  end
end
