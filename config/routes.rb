Rails.application.routes.draw do
    root "landing#start"

    get  "/unterstuetzer",    to: "landing#unterstuetzer",    as: :unterstuetzer
    post "/kontakt",          to: "landing#create_kontakt",   as: :kontakt

    get  "/impressum",        to: "landing#impressum",        as: :impressum
    get  "/datenschutz",      to: "landing#datenschutz",      as: :datenschutz

    get  "/sitemap.xml",      to: "landing#sitemap", defaults: { format: :xml }, as: :sitemap

end