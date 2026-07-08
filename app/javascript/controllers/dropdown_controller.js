import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "hidden"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.boundClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle() {
    this.openValue = !this.openValue
    this.menuTarget.classList.toggle("hidden", !this.openValue)
    this.syncAria()
  }

  close() {
    this.openValue = false
    this.menuTarget.classList.add("hidden")
    this.syncAria()
  }

  selectOption(event) {
    const option = event.currentTarget
    const value = option.dataset.value
    const label = option.textContent.trim()

    this.hiddenTarget.value = value
    this.buttonTarget.querySelector('[data-selected-label]').textContent = label

    this.close()
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  syncAria() {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", this.openValue)
    }
  }
}
