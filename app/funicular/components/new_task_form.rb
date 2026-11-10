# タスク追加フォーム。ルートへの追加と、サブタスクへの分割の両方で使う。
#
# props:
#   form_id      DOM id の接頭辞（同じ画面に複数出るので一意にする）
#   placeholder
#   autofocus    true なら表示時に入力欄へフォーカス
#   on_submit    ->(title, estimate_or_nil) {}
#   on_cancel    ->() {}（省略可。Esc とキャンセルボタンで呼ぶ）
class NewTaskForm < Funicular::Component
  ESTIMATE_CHOICES = [ 1, 2, 3, 4, 6, 8 ]

  def component_mounted
    return unless props[:autofocus]
    field = JS.document.getElementById(title_id)
    field.focus if field
  end

  def title_id
    "#{props[:form_id]}-title"
  end

  def estimate_id
    "#{props[:form_id]}-estimate"
  end

  def handle_submit(event)
    event.preventDefault
    field = JS.document.getElementById(title_id)
    title = field[:value].to_s.strip
    return if title.empty?

    estimate_field = JS.document.getElementById(estimate_id)
    raw = estimate_field[:value].to_s
    estimate = raw.empty? ? nil : raw.to_i

    props[:on_submit].call(title, estimate)
    field[:value] = ""
    field.focus
  end

  def handle_keydown(event)
    return unless event[:key].to_s == "Escape"
    cancel = props[:on_cancel]
    cancel.call if cancel
  end

  def handle_cancel(_event)
    props[:on_cancel].call
  end

  def render
    form(class: "fmn-new", onsubmit: :handle_submit) do
      input(type: "text", id: title_id, class: "fmn-new__title",
            placeholder: props[:placeholder], autocomplete: "off",
            "aria-label": props[:placeholder], onkeydown: :handle_keydown)
      tag("select", id: estimate_id, class: "fmn-new__estimate", "aria-label": "見積もり（ポモドーロ）") do
        option(value: "") { "🍅 ?" }
        ESTIMATE_CHOICES.each do |n|
          option(value: n.to_s) { "🍅 #{n}" }
        end
      end
      button(type: "submit", class: "fmn-btn fmn-btn--primary") { "追加" }
      if props[:on_cancel]
        button(type: "button", class: "fmn-btn", onclick: :handle_cancel) { "やめる" }
      end
    end
  end
end
