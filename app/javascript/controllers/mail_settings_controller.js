import { Controller } from "@hotwired/stimulus"

// The mail settings form:
//  1. provider/port dropdowns that fill the host, port and username placeholder;
//  2. "Send test email" posts the values CURRENTLY in the form (not the saved ones) and shows
//     the result inline — the form is never re-rendered, so a typed password survives testing.
export default class extends Controller {
  static targets = ["address", "port", "userName", "testResult"]
  static values = { testUrl: String }

  chooseHost(event) {
    const option = event.target.selectedOptions[0]
    if (!option.value) return

    if (option.value === "custom") {
      this.addressTarget.value = ""
      this.addressTarget.closest("details")?.setAttribute("open", "")
      this.addressTarget.focus()
      return
    }

    this.addressTarget.value = option.value
    this.userNameTarget.placeholder = option.dataset.hint || "SMTP username"
  }

  choosePort(event) {
    const value = event.target.value
    if (value === "custom") {
      this.portTarget.value = ""
      this.portTarget.focus()
    } else {
      this.portTarget.value = value
    }
  }

  async test() {
    this.setResult("Sending…", "neutral")

    const body = new FormData(this.element)
    body.delete("_method") // POST to the test endpoint, not the form's PATCH
    // The form's own authenticity_token is scoped (per-form CSRF) to its PATCH action, so it's
    // rejected at POST /test. Drop it and send the global token from the <meta> tag via the
    // header, which Rails accepts for any endpoint.
    body.delete("authenticity_token")
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(this.testUrlValue, {
        method: "POST",
        body,
        headers: { Accept: "application/json", "X-CSRF-Token": csrfToken }
      })
      const data = await response
        .json()
        .catch(() => ({ ok: false, message: `Server error (${response.status}).` }))
      this.setResult(data.message, data.ok ? "ok" : "error")
    } catch {
      this.setResult("Couldn't reach the server — try again.", "error")
    }
  }

  setResult(message, tone) {
    this.testResultTarget.textContent = message
    this.testResultTarget.className = {
      neutral: "text-sm text-slate-500",
      ok: "text-sm text-emerald-700",
      error: "text-sm text-rose-700"
    }[tone]
  }
}
