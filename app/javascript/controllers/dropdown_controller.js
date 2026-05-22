import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "hidden"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  toggle() {
    this.openValue = !this.openValue
    this.menuTarget.classList.toggle("hidden", !this.openValue)
  }

  selectOption(event) {
    const option = event.currentTarget
    const value = option.dataset.value
    const label = option.textContent.trim()

    this.hiddenTarget.value = value
    this.buttonTarget.querySelector('[data-selected-label]').textContent = label

    this.openValue = false
    this.menuTarget.classList.add("hidden")
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.openValue = false
      this.menuTarget.classList.add("hidden")
    }
  }
}


