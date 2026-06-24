// Configure your import map in config/importmap.rb.
// Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "controllers"

const ACTIVE_SERVICE_TAB_CLASSES = [
    "bg-green-700",
    "text-white",
    "shadow-sm",
    "hover:bg-green-800",
    "hover:text-white"
]

const INACTIVE_SERVICE_TAB_CLASSES = [
    "bg-transparent",
    "text-slate-700",
    "hover:bg-white",
    "hover:text-green-700"
]

const ALL_SERVICE_TAB_STATE_CLASSES = [
    ...ACTIVE_SERVICE_TAB_CLASSES,
    ...INACTIVE_SERVICE_TAB_CLASSES
]

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

function setServiceTabClasses(button, isSelected) {
    ALL_SERVICE_TAB_STATE_CLASSES.forEach((className) => {
        button.classList.remove(className)
    })

    const classesToAdd = isSelected
        ? ACTIVE_SERVICE_TAB_CLASSES
        : INACTIVE_SERVICE_TAB_CLASSES

    classesToAdd.forEach((className) => {
        button.classList.add(className)
    })
}

function activateServiceTab(container, tabName, updateHash = false) {
    const buttons = container.querySelectorAll("[data-service-tab]")
    const panels = container.querySelectorAll("[data-service-panel]")

    const selectedButton = container.querySelector(
        `[data-service-tab="${tabName}"]`
    )

    const selectedPanel = container.querySelector(
        `[data-service-panel="${tabName}"]`
    )

    if (!selectedButton || !selectedPanel) {
        return false
    }

    buttons.forEach((button) => {
        const isSelected = button === selectedButton

        button.setAttribute("aria-selected", isSelected.toString())
        button.tabIndex = isSelected ? 0 : -1

        setServiceTabClasses(button, isSelected)
    })

    panels.forEach((panel) => {
        panel.hidden = panel !== selectedPanel
    })

    if (updateHash) {
        window.history.replaceState(null, "", `#${tabName}`)
    }

    return true
}

function serviceTabNameFromHash() {
    const tabName = window.location.hash.substring(1)

    if (["beitritt", "kontakt", "portal"].includes(tabName)) {
        return tabName
    }

    return null
}

function initializeServiceTabs() {
    document.querySelectorAll("[data-service-tabs]").forEach((container) => {
        const buttons = Array.from(
            container.querySelectorAll("[data-service-tab]")
        )

        if (buttons.length === 0) {
            return
        }

        if (container.dataset.tabsInitialized !== "true") {
            container.dataset.tabsInitialized = "true"

            buttons.forEach((button, index) => {
                button.addEventListener("click", () => {
                    activateServiceTab(
                        container,
                        button.dataset.serviceTab,
                        true
                    )
                })

                button.addEventListener("keydown", (event) => {
                    const supportedKeys = [
                        "ArrowLeft",
                        "ArrowRight",
                        "Home",
                        "End"
                    ]

                    if (!supportedKeys.includes(event.key)) {
                        return
                    }

                    event.preventDefault()

                    let targetIndex = index

                    if (event.key === "ArrowLeft") {
                        targetIndex =
                            (index - 1 + buttons.length) % buttons.length
                    }

                    if (event.key === "ArrowRight") {
                        targetIndex = (index + 1) % buttons.length
                    }

                    if (event.key === "Home") {
                        targetIndex = 0
                    }

                    if (event.key === "End") {
                        targetIndex = buttons.length - 1
                    }

                    const targetButton = buttons[targetIndex]

                    activateServiceTab(
                        container,
                        targetButton.dataset.serviceTab,
                        true
                    )

                    targetButton.focus()
                })
            })
        }

        const tabName = serviceTabNameFromHash() || "beitritt"

        activateServiceTab(container, tabName)
    })
}

function openServiceTabFromHash() {
    const tabName = serviceTabNameFromHash()

    if (!tabName) {
        return
    }

    const container = document.querySelector("[data-service-tabs]")

    if (!container) {
        return
    }

    const activated = activateServiceTab(container, tabName)

    if (!activated) {
        return
    }

    const target = document.getElementById(tabName)

    if (target) {
        window.requestAnimationFrame(() => {
            target.scrollIntoView({
                behavior: "smooth",
                block: "start"
            })
        })
    }
}

function initializePageInteractions() {
    initializeServiceTabs()
    openFaqFromHash()
    openServiceTabFromHash()
}

document.addEventListener("DOMContentLoaded", initializePageInteractions)
document.addEventListener("turbo:load", initializePageInteractions)

window.addEventListener("hashchange", () => {
    openFaqFromHash()
    openServiceTabFromHash()
})