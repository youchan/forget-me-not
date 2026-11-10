# タスクの詳細編集（タイトル・見積もり・開始日・期限）。
#
# 入力欄は DOM から直接読む（フォーカス中の input には再描画の value が
# 反映されないため、状態に持たずに保存時に読むほうが素直）。
#
# props:
#   task       タスクのハッシュ
#   is_leaf    子がないなら true（見積もりの説明を出し分ける）
#   on_save    ->(attrs) {}
#   on_cancel  ->() {}
class TaskEditor < Funicular::Component
  ESTIMATE_CHOICES = [ 1, 2, 3, 4, 5, 6, 8, 10, 12 ]

  def component_mounted
    field = JS.document.getElementById(field_id("title"))
    field.focus if field
  end

  def field_id(name)
    "task-#{props[:task]["id"]}-#{name}"
  end

  def field_value(name)
    JS.document.getElementById(field_id(name))[:value].to_s.strip
  end

  def handle_save(event)
    event.preventDefault
    estimate = field_value("estimate")
    starts_on = field_value("starts_on")
    due_on = field_value("due_on")
    props[:on_save].call(
      title: field_value("title"),
      estimate_pomodoros: estimate.empty? ? nil : estimate.to_i,
      starts_on: starts_on.empty? ? nil : starts_on,
      due_on: due_on.empty? ? nil : due_on
    )
  end

  def handle_keydown(event)
    props[:on_cancel].call if event[:key].to_s == "Escape"
  end

  def handle_cancel(_event)
    props[:on_cancel].call
  end

  def render
    task = props[:task]
    current = task["estimate_pomodoros"]

    form(class: "fmn-editor", onsubmit: :handle_save, onkeydown: :handle_keydown) do
      div(class: "fmn-editor__row") do
        label(for: field_id("title"), class: "fmn-editor__label") { "タイトル" }
        input(type: "text", id: field_id("title"), value: task["title"],
              class: "fmn-editor__input", autocomplete: "off")
      end
      div(class: "fmn-editor__grid") do
        div(class: "fmn-editor__row") do
          label(for: field_id("estimate"), class: "fmn-editor__label") { "見積もり" }
          tag("select", id: field_id("estimate"), class: "fmn-editor__input") do
            option(value: "", selected: current.nil?) { "未設定" }
            ESTIMATE_CHOICES.each do |n|
              option(value: n.to_s, selected: current.to_i == n) do
                "🍅 #{n}（#{n * 30}分）"
              end
            end
          end
        end
        div(class: "fmn-editor__row") do
          label(for: field_id("starts_on"), class: "fmn-editor__label") { "開始" }
          input(type: "date", id: field_id("starts_on"), value: task["starts_on"].to_s,
                class: "fmn-editor__input")
        end
        div(class: "fmn-editor__row") do
          label(for: field_id("due_on"), class: "fmn-editor__label") { "期限" }
          input(type: "date", id: field_id("due_on"), value: task["due_on"].to_s,
                class: "fmn-editor__input")
        end
      end
      unless props[:is_leaf]
        p(class: "fmn-editor__note") do
          "サブタスクがあるので、サイズはサブタスクの見積もりの合計で表示されます。ここでの見積もりは最初の見立てとして残ります。"
        end
      end
      div(class: "fmn-editor__actions") do
        button(type: "submit", class: "fmn-btn fmn-btn--primary") { "保存" }
        button(type: "button", class: "fmn-btn", onclick: :handle_cancel) { "やめる" }
      end
    end
  end
end
