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

const SERVICE_TAB_NAMES = ["beitritt", "kontakt", "portal"]

// Zerlegt den URL-Hash in Reiter-Name und optionalen Zusatz.
// Beispiele:
//   "#beitritt"         -> { tab: "beitritt", suffix: null }
//   "#beitritt-00BA21"  -> { tab: "beitritt", suffix: "00BA21" }
//   "#kontakt"          -> { tab: "kontakt",  suffix: null }
//   "#faq-standort"     -> null  (kein Service-Reiter)
function parseServiceHash() {
    const raw = window.location.hash.substring(1)

    if (!raw) {
        return null
    }

    const separatorIndex = raw.indexOf("-")
    const tab = separatorIndex === -1 ? raw : raw.slice(0, separatorIndex)

    if (!SERVICE_TAB_NAMES.includes(tab)) {
        return null
    }

    const suffix = separatorIndex === -1 ? null : raw.slice(separatorIndex + 1)

    return { tab, suffix: suffix || null }
}

function serviceTabNameFromHash() {
    const parsed = parseServiceHash()

    return parsed ? parsed.tab : null
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

// Wählt bei "#beitritt-00BA21" die passende Energiegemeinschaft vor, indem die
// zugehörige Karte geklickt wird. Die Karte trägt die Zuordnung (BKZ -> Onboarding)
// bereits als data-Attribute, daher wird die Logik des eeg-select-Controllers
// unverändert wiederverwendet. Rückgabe: true, wenn eine Karte gewählt wurde.
function selectEegCardFromSuffix(container, suffix) {
    if (!suffix) {
        return false
    }

    const normalized = suffix.trim().toUpperCase()
    const cards = Array.from(container.querySelectorAll("[data-bkz]"))
    const card = cards.find((c) => normalized.indexOf(c.dataset.bkz) === 0)

    if (!card) {
        return false
    }

    // Ein Frame warten, damit das Panel sichtbar ist und der Stimulus-Controller
    // verbunden ist, bevor der Klick das Formular lädt und dorthin scrollt.
    window.requestAnimationFrame(() => card.click())

    return true
}

function openServiceTabFromHash() {
    const parsed = parseServiceHash()

    if (!parsed) {
        return
    }

    const container = document.querySelector("[data-service-tabs]")

    if (!container) {
        return
    }

    const activated = activateServiceTab(container, parsed.tab)

    if (!activated) {
        return
    }

    // Direktlink auf ein bestimmtes Beitrittsformular (z. B. "#beitritt-00BA21"):
    // Karte vorwählen und zu Schritt 2 scrollen. Der Klick übernimmt das Scrollen.
    if (parsed.tab === "beitritt" && selectEegCardFromSuffix(container, parsed.suffix)) {
        return
    }

    const target = document.getElementById(parsed.tab)

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