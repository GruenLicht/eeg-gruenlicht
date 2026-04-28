// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function openFaqFromHash() {
    if (!window.location.hash) {
        return
    }

    const targetId = window.location.hash.substring(1)
    const target = document.getElementById(targetId)

    if (!target || target.tagName.toLowerCase() !== "details") {
        return
    }

    target.open = true

    window.requestAnimationFrame(() => {
        target.scrollIntoView({
            behavior: "smooth",
            block: "start"
        })
    })
}

document.addEventListener("turbo:load", openFaqFromHash)
window.addEventListener("hashchange", openFaqFromHash)