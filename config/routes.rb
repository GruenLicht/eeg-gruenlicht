Rails.application.routes.draw do
    root "landing#start"

    get  "/preise",           to: "landing#preise",           as: :preise
    get  "/unterstuetzer",    to: "landing#unterstuetzer",    as: :unterstuetzer
    post "/kontakt",          to: "landing#create_kontakt",   as: :kontakt

    get  "/blog",             to: "blog#index",               as: :blog
    get  "/blog/:slug",       to: "blog#show",                as: :blog_post,
                              constraints: { slug: /[a-z0-9]+(?:-[a-z0-9]+)*/ }

    get  "/impressum",        to: "landing#impressum",        as: :impressum
    get  "/datenschutz",      to: "landing#datenschutz",      as: :datenschutz

    get  "/app/datenloeschung", to: "landing#datenloeschung", as: :app_datenloeschung

    get  "/sitemap.xml",      to: "landing#sitemap", defaults: { format: :xml }, as: :sitemap

end