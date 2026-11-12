import { Controller } from "@hotwired/stimulus"

// フォームの要素を変えたら即そのフォームを送信する（カテゴリの切り替えなど）
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
