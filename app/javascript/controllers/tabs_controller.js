import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["tab", "panel"]

    static values = {
        activeClass: String,
        inactiveClass: String
    }

    connect() {
        const selectedIndex = this.tabTargets.findIndex((tab) => {
            return tab.getAttribute("aria-selected") === "true"
        })

        this.activate(selectedIndex >= 0 ? selectedIndex : 0)
    }

    select(event) {
        event.preventDefault()

        const selectedTab = event.currentTarget
        const selectedIndex = this.tabTargets.indexOf(selectedTab)

        if (selectedIndex < 0) {
            return
        }

        this.activate(selectedIndex)
    }

    handleKeydown(event) {
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

        const currentIndex = this.tabTargets.indexOf(event.currentTarget)
        let nextIndex = currentIndex

        switch (event.key) {
            case "ArrowLeft":
                nextIndex =
                    (currentIndex - 1 + this.tabTargets.length) %
                    this.tabTargets.length
                break
            case "ArrowRight":
                nextIndex = (currentIndex + 1) % this.tabTargets.length
                break
            case "Home":
                nextIndex = 0
                break
            case "End":
                nextIndex = this.tabTargets.length - 1
                break
        }

        this.activate(nextIndex)
        this.tabTargets[nextIndex].focus()
    }

    activate(selectedIndex) {
        this.tabTargets.forEach((tab, index) => {
            const isActive = index === selectedIndex

            tab.setAttribute("aria-selected", isActive.toString())
            tab.tabIndex = isActive ? 0 : -1

            this.removeClasses(tab, this.activeClasses)
            this.removeClasses(tab, this.inactiveClasses)

            this.addClasses(
                tab,
                isActive ? this.activeClasses : this.inactiveClasses
            )
        })

        this.panelTargets.forEach((panel, index) => {
            const isActive = index === selectedIndex

            panel.classList.toggle("hidden", !isActive)
            panel.hidden = !isActive
        })
    }

    get activeClasses() {
        return this.classListFromAttribute(
            "data-tabs-active-class"
        )
    }

    get inactiveClasses() {
        return this.classListFromAttribute(
            "data-tabs-inactive-class"
        )
    }

    classListFromAttribute(attributeName) {
        const value = this.element.getAttribute(attributeName)

        if (!value) {
            return []
        }

        return value
            .split(/\s+/)
            .map((className) => className.trim())
            .filter(Boolean)
    }

    addClasses(element, classes) {
        classes.forEach((className) => {
            element.classList.add(className)
        })
    }

    removeClasses(element, classes) {
        classes.forEach((className) => {
            element.classList.remove(className)
        })
    }
}