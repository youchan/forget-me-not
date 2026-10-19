import { Controller } from "@hotwired/stimulus"
import { get } from "@github/webauthn-json"
import { postJSON } from "csrf"

export default class extends Controller {
  static targets = ["email", "error", "submit"]

  async login(event) {
    event.preventDefault()
    this.clearError()
    this.submitTarget.disabled = true

    try {
      const email = this.emailTarget.value
      const options = await postJSON("/sessions/options", { email })
      const credential = await get({ publicKey: options })
      const result = await postJSON("/sessions", { credential })
      window.location.href = result.redirect_to
    } catch (error) {
      this.showError(error.message)
    } finally {
      this.submitTarget.disabled = false
    }
  }

  showError(message) {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clearError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
