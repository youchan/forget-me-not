# タスク画面の本体。全タスクを1回の GET /tasks.json で読み込み、
# 状態として持ったフラットな配列から TaskTree で木を組んで描画する。
# 変更は1件ずつ JSON API に送り、返ってきたタスクで状態を置き換える。
class TaskBoard < Funicular::Component
  def initialize_state
    {
      tasks: [],
      loading: true,
      error: nil,
      collapsed: [],        # 折りたたんでいるタスクの id
      editing_id: nil,      # 詳細編集を開いているタスク
      adding_under_id: nil, # サブタスク追加フォームを開いているタスク
      hide_done: false,
      today: today_string
    }
  end

  def component_mounted
    load_tasks
  end

  # PicoRuby の Time には month が無いので、日付はブラウザの Date から取る
  def today_string
    JS.eval(
      "(function(){var d=new Date();" \
      "return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0')})()"
    ).to_s
  end

  # ---------------------------------------------------------------
  # サーバーとのやり取り
  # ---------------------------------------------------------------
  def load_tasks
    Funicular::HTTP.get("/tasks.json") do |response|
      if response.ok
        patch(tasks: response.data, loading: false, error: nil)
      else
        patch(loading: false, error: response.error_message || "タスクを読み込めませんでした")
      end
    end
  end

  def create_task(attrs)
    Funicular::HTTP.post("/tasks.json", { task: attrs }) do |response|
      if response.ok
        patch(tasks: state[:tasks] + [ response.data ], error: nil)
      else
        show_error(response, "追加できませんでした")
      end
    end
  end

  def update_task(id, attrs, &after)
    Funicular::HTTP.patch("/tasks/#{id}.json", { task: attrs }) do |response|
      if response.ok
        replace_task(response.data)
        after.call if after
      else
        show_error(response, "保存できませんでした")
      end
    end
  end

  def delete_task(task)
    ids = tree.subtree_ids(task)
    Funicular::HTTP.delete("/tasks/#{task["id"]}.json") do |response|
      if response.ok
        patch(tasks: state[:tasks].reject { |t| ids.include?(t["id"]) }, error: nil)
      else
        show_error(response, "削除できませんでした")
      end
    end
  end

  def replace_task(updated)
    patch(
      tasks: state[:tasks].map { |t| t["id"] == updated["id"] ? updated : t },
      error: nil
    )
  end

  def show_error(response, fallback)
    patch(error: response.error_message || fallback)
  end

  def tree
    TaskTree.new(state[:tasks])
  end

  # ---------------------------------------------------------------
  # 画面操作（イベントハンドラ。ループの中で使うものは lambda を返す）
  # ---------------------------------------------------------------
  def add_root_task(title, estimate)
    create_task(title: title, estimate_pomodoros: estimate)
  end

  def add_subtask(parent_id)
    ->(title, estimate) {
      create_task(title: title, estimate_pomodoros: estimate, parent_id: parent_id)
      # 折りたたんでいたら、追加したものが見えるように開く
      patch(collapsed: state[:collapsed].reject { |id| id == parent_id })
    }
  end

  def toggle_done(task)
    -> { update_task(task["id"], { done: !(task["done"] == true) }) }
  end

  def toggle_collapse(task)
    -> {
      id = task["id"]
      collapsed = state[:collapsed]
      patch(collapsed: collapsed.include?(id) ? collapsed.reject { |c| c == id } : collapsed + [ id ])
    }
  end

  def open_editor(task)
    -> { patch(editing_id: task["id"], adding_under_id: nil) }
  end

  def close_editor
    patch(editing_id: nil)
  end

  def save_editor(task)
    ->(attrs) { update_task(task["id"], attrs) { close_editor } }
  end

  def open_add_form(task)
    -> { patch(adding_under_id: task["id"], editing_id: nil) }
  end

  def close_add_form
    patch(adding_under_id: nil)
  end

  def confirm_delete(task)
    -> {
      count = tree.subtree_ids(task).size - 1
      message = if count > 0
        "「#{task["title"]}」とサブタスク#{count}件を削除します。よろしいですか？"
      else
        "「#{task["title"]}」を削除します。よろしいですか？"
      end
      delete_task(task) if JS.global.confirm(message).to_s == "true"
    }
  end

  def handle_toggle_hide_done(_event)
    patch(hide_done: !state[:hide_done])
  end

  def handle_dismiss_error(_event)
    patch(error: nil)
  end

  # ---------------------------------------------------------------
  # 表示
  # ---------------------------------------------------------------
  def format_date(date_string)
    parts = date_string.to_s.split("-")
    return "" if parts.size < 3
    "#{parts[1].to_i}/#{parts[2].to_i}"
  end

  # 期間の表示と、期限の状態（:overdue / :today / nil）
  def period_of(task)
    starts_on = task["starts_on"]
    due_on = task["due_on"]
    return nil if starts_on.nil? && due_on.nil?

    text = "#{starts_on ? format_date(starts_on) : ""}〜#{due_on ? format_date(due_on) : ""}"
    status = nil
    if due_on && task["done"] != true
      if due_on.to_s < state[:today]
        status = :overdue
      elsif due_on.to_s == state[:today]
        status = :today
      end
    end
    [ text, status ]
  end

  def size_label(t, task, kind)
    if kind == :big
      r = t.rollup(task)
      text = "🍅 残り#{r[:remaining]}"
      text += "+?" if r[:unestimated] > 0
      text += " / 計#{r[:total]}"
      [ text, "#{r[:done_count]}/#{r[:leaf_count]} 完了" ]
    elsif task["estimate_pomodoros"]
      [ "🍅 #{task["estimate_pomodoros"]}", nil ]
    else
      [ nil, nil ]
    end
  end

  def visible?(t, task)
    return true unless state[:hide_done]
    task["done"] != true
  end

  def render_node(t, task, depth)
    kind = t.kind_of(task)
    children = t.children_of(task)
    collapsed = state[:collapsed].include?(task["id"])
    done = task["done"] == true
    size_text, progress_text = size_label(t, task, kind)
    period = period_of(task)

    row_class = "fmn-row fmn-row--#{kind}"
    row_class += " is-done" if done

    li(key: task["id"], class: "fmn-node") do
      div(class: row_class) do
        if children.empty?
          span(class: "fmn-toggle fmn-toggle--leaf") { "" }
        else
          button(class: "fmn-toggle", onclick: toggle_collapse(task),
                 "aria-label": collapsed ? "開く" : "閉じる",
                 "aria-expanded": (!collapsed).to_s) { collapsed ? "▸" : "▾" }
        end
        input(type: "checkbox", class: "fmn-check", checked: done,
              "aria-label": "完了", onchange: toggle_done(task))
        button(class: "fmn-title", onclick: open_editor(task), title: "クリックで編集") { task["title"] }
        if kind == :split
          button(class: "fmn-badge fmn-badge--split", onclick: open_add_form(task),
                 title: "サブタスクに分割する") { "✂ 分割しよう" }
        else
          span(class: "fmn-badge fmn-badge--#{kind}") { TaskTree::KIND_LABELS[kind] }
        end
        span(class: "fmn-meta") do
          span(class: "fmn-size") { size_text.to_s }
          span(class: "fmn-progress") { progress_text.to_s }
          if period
            span(class: "fmn-period#{period[1] ? " is-#{period[1]}" : ""}") do
              period[1] == :overdue ? "期限切れ #{period[0]}" : period[0]
            end
          end
        end
        button(class: "fmn-icon", onclick: open_add_form(task), title: "サブタスクを追加") { "＋" }
        button(class: "fmn-icon fmn-icon--danger", onclick: confirm_delete(task), title: "削除") { "×" }
      end

      div(class: "fmn-slot") do
        render_slot(t, task, children)
      end

      visible_children = children.select { |c| visible?(t, c) }
      if !visible_children.empty? && !collapsed
        ul(class: "fmn-children") do
          visible_children.each { |child| render_node(t, child, depth + 1) }
        end
      end
    end
  end

  # 行の下に開く詳細編集かサブタスク追加フォーム（どちらか1つ）
  def render_slot(t, task, children)
    if state[:editing_id] == task["id"]
      component(TaskEditor,
                key: "editor-#{task["id"]}",
                preserve: true,
                task: task,
                is_leaf: children.empty?,
                on_save: save_editor(task),
                on_cancel: -> { close_editor })
    end

    if state[:adding_under_id] == task["id"]
      div(class: "fmn-subform") do
        component(NewTaskForm,
                  key: "add-#{task["id"]}",
                  preserve: true,
                  form_id: "add-under-#{task["id"]}",
                  placeholder: "「#{task["title"]}」のサブタスク",
                  autofocus: true,
                  on_submit: add_subtask(task["id"]),
                  on_cancel: -> { close_add_form })
      end
    end
  end

  def render_summary(t)
    counts = t.open_leaf_counts
    div(class: "fmn-summary") do
      next if state[:tasks].empty?
      [ :todo, :split, :unestimated, :big ].each do |kind|
        span(key: kind.to_s, class: "fmn-summary__item fmn-badge fmn-badge--#{kind}") do
          "#{TaskTree::KIND_LABELS[kind]} #{counts[kind]}"
        end
      end
    end
  end

  def render
    t = tree
    roots = t.roots.select { |r| visible?(t, r) }

    div(class: "fmn-board") do
      div(class: "fmn-head") do
        h1(class: "fmn-head__title") { "タスク" }
        label(class: "fmn-head__option") do
          input(type: "checkbox", checked: state[:hide_done], onchange: :handle_toggle_hide_done)
          span { "完了したものを隠す" }
        end
      end

      # 条件付きの要素は常に存在する入れ物に入れる。兄弟の位置がずれると
      # 差分更新でその後ろの要素（編集中のフォームなど）が作り直されてしまうため
      div(class: "fmn-error-slot", role: "alert") do
        if state[:error]
          div(class: "fmn-error") do
            span { state[:error].to_s }
            button(class: "fmn-icon", onclick: :handle_dismiss_error, "aria-label": "閉じる") { "×" }
          end
        end
      end

      # preserve: true がないと、lambda を渡した子コンポーネントは親の再描画のたびに
      # 作り直され、入力途中の文字が消える（Funicular 0.5.2 の差分更新の仕様）
      component(NewTaskForm,
                preserve: true,
                form_id: "add-root",
                placeholder: "やることを追加（Enter）",
                autofocus: false,
                on_submit: ->(title, estimate) { add_root_task(title, estimate) })

      render_summary(t)

      if state[:loading]
        p(class: "fmn-empty") { "読み込み中…" }
      elsif roots.empty?
        p(class: "fmn-empty") do
          state[:tasks].empty? ? "まだタスクがありません。上の欄から追加してください。" : "未完了のタスクはありません 🎉"
        end
      else
        ul(class: "fmn-tree") do
          roots.each { |task| render_node(t, task, 0) }
        end
      end
    end
  end
end
