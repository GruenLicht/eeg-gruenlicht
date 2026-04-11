Rails.application.routes.draw do
    root "landing#start"

    get  "/mitmachen",        to: "landing#mitmachen",        as: :mitmachen
    get  "/so-funktionierts", to: "landing#so_funktionierts", as: :so_funktionierts
    get  "/ueber-uns",        to: "landing#ueber_uns",        as: :ueber_uns
    get  "/kontakt",          to: "landing#kontakt",          as: :kontakt_seite

    post "/kontakt",          to: "landing#create_kontakt",   as: :kontakt

    get  "/impressum",        to: "landing#impressum",        as: :impressum
    get  "/datenschutz",      to: "landing#datenschutz",      as: :datenschutz
end