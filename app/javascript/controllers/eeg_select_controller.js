import { Controller } from "@hotwired/stimulus"

// Routet den Beitritt auf die richtige Energiegemeinschaft anhand der
// Beauskunftungskennzahl (BKZ). Karten-Klick oder BKZ-Eingabe laden das
// passende Onboarding-Formular in das iframe.
//
// Mapping pflegen: BKZ-Präfix -> { id: <Onboarding-UUID>, name: <Anzeigename> }
export default class extends Controller {
    static targets = ["card", "input", "message", "form", "frame", "link", "name"]
    static values = { base: String }

    get eegs() {
        return {
            "00BA21": { id: "cb81cc8e-a2a3-4660-b4cc-067c15d9b277", name: "EEG Bad Vöslau/Sooß" },
            "00BA22": { id: "437a846f-a56f-4f35-86b0-0ff31041b915", name: "EEG Bad Vöslau" },
            "00BA23": { id: "e10c2146-c551-4e73-8515-573c30be6c7e", name: "EEG Bad Vöslau-Flugfeld" }
        }
    }

    selectCard(event) {
        const btn = event.currentTarget
        this.highlight(btn)
        this.clearMessage()
        this.load(btn.dataset.eegId, btn.dataset.eegName)
    }

    checkBkz(event) {
        if (event) event.preventDefault()
        const value = (this.inputTarget.value || "").trim().toUpperCase().replace(/\s+/g, "")
        if (!value) {
            this.showMessage("Bitte geben Sie Ihre Beauskunftungskennzahl ein.", "amber")
            return
        }
        const prefix = Object.keys(this.eegs).find((p) => value.indexOf(p) === 0)
        if (prefix) {
            const eeg = this.eegs[prefix]
            this.showMessage("Zuständig ist die " + eeg.name + ".", "green")
            this.highlightByPrefix(prefix)
            this.load(eeg.id, eeg.name)
        } else {
            this.showMessage(
                "Für diese Kennzahl gibt es derzeit keine zugeordnete Energiegemeinschaft. " +
                "Bitte kontaktieren Sie uns über den Reiter „Kontaktanfrage“ — wir prüfen Ihren Standort gerne.",
                "amber"
            )
        }
    }

    keydown(event) {
        if (event.key === "Enter") this.checkBkz(event)
    }

    // Wechselt auf den "Kontaktanfrage"-Reiter (von application.js verdrahtet).
    openKontakt(event) {
        if (event) event.preventDefault()
        const tab = document.getElementById("service-tab-kontakt")
        if (tab) {
            tab.click()
            tab.scrollIntoView({ behavior: "smooth", block: "start" })
        }
    }

    load(id, name) {
        const url = this.baseValue + id
        this.frameTarget.src = url
        this.linkTarget.href = url
        this.nameTarget.textContent = name
        this.formTarget.hidden = false
        this.formTarget.scrollIntoView({ behavior: "smooth", block: "start" })
    }

    highlight(btn) {
        this.cardTargets.forEach((c) => c.classList.remove("border-green-600", "bg-green-50"))
        btn.classList.add("border-green-600", "bg-green-50")
    }

    highlightByPrefix(prefix) {
        const btn = this.cardTargets.find((c) => c.dataset.bkz === prefix)
        if (btn) this.highlight(btn)
    }

    showMessage(text, color) {
        this.messageTarget.hidden = false
        this.messageTarget.className =
            "mt-2 text-sm " + (color === "green" ? "text-green-700" : "text-amber-700")
        this.messageTarget.textContent = text
    }

    clearMessage() {
        this.messageTarget.hidden = true
    }
}
