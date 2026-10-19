import { Controller } from "@hotwired/stimulus"
import { create } from "@github/webauthn-json"
import { postJSON } from "csrf"

export default class extends Controller {
  static targets = ["email", "nickname", "error", "submit"]

  async register(event) {
    event.preventDefault()
    this.clearError()
    this.submitTarget.disabled = true

    try {
      const email = this.emailTarget.value
      const options = await postJSON("/registrations/options", { email })
      const credential = await create({ publicKey: options })
      const result = await postJSON("/registrations", {
        credential,
        nickname: this.hasNicknameTarget ? this.nicknameTarget.value : null
      })
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
