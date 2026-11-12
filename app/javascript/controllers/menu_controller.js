import { Controller } from "@hotwired/stimulus"

// ハンバーガーメニューの開閉。メニュー外のクリックと Esc で閉じる
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.hide = this.hide.bind(this)
    document.addEventListener("click", this.hide)
    document.addEventListener("keydown", this.hideOnEscape.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.hide)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  hide() {
    this.menuTarget.classList.add("hidden")
  }

  hideOnEscape(event) {
    if (event.key === "Escape") this.hide()
  }
}
