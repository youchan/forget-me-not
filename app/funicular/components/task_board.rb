# タスク画面の本体。全タスクを1回の GET /tasks.json で読み込み、
# フラットな配列から TaskTree で木を組んで扱う。
#
# 表示は Remember The Milk 風の2ペイン・ドリルダウン:
#   左ペイン = 「今見ている階層」の一覧（current_parent_id の子たち）
#   右ペイン = 選択中タスク（selected_id）の詳細・編集・サブタスク一覧
# 右ペインのサブタスクをクリックすると、そのサブタスクの階層へ「降りる」
# （current_parent_id がクリックしたタスクの親、つまり選択中タスク自身になる）。
# パンくずで親の階層へ戻れる。
#
# 変更は1件ずつ JSON API に送り、返ってきたタスクで状態を置き換える。
class TaskBoard < Funicular::Component
  ESTIMATE_CHOICES = [ 1, 2, 3, 4, 5, 6, 8, 10, 12 ]

  def initialize_state
    {
      tasks: [],
      loading: true,
      error: nil,
      current_parent_id: nil, # 左ペインに出す階層。nil はルート
      selected_id: nil,       # 右ペインで開いているタスク
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
    Funicular::HTTP.get("#{Funicular.mount_base_path}/tasks.json") do |response|
      if response.ok
        patch(tasks: response.data, loading: false, error: nil)
      else
        patch(loading: false, error: response.error_message || "タスクを読み込めませんでした")
      end
    end
  end

  def create_task(attrs)
    Funicular::HTTP.post("#{Funicular.mount_base_path}/tasks.json", { task: attrs }) do |response|
      if response.ok
        patch(tasks: state[:tasks] + [ response.data ], error: nil)
      else
        show_error(response, "追加できませんでした")
      end
    end
  end

  def update_task(id, attrs, &after)
    Funicular::HTTP.patch("#{Funicular.mount_base_path}/tasks/#{id}.json", { task: attrs }) do |response|
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
    Funicular::HTTP.delete("#{Funicular.mount_base_path}/tasks/#{task["id"]}.json") do |response|
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
  # 画面操作
  # ---------------------------------------------------------------

  # 左ペインの行をクリック: 同じ階層のまま、右ペインの選択だけ変える
  def select_task(task_id)
    -> { patch(selected_id: task_id) }
  end

  # 右ペインのサブタスク一覧をクリック: そのタスクの階層へ降りる
  def drill_into(child_id)
    parent_id = state[:selected_id]
    -> { patch(current_parent_id: parent_id, selected_id: child_id) }
  end

  # パンくずをクリック: その階層まで戻る
  def go_to_breadcrumb(parent_id, task_id)
    -> { patch(current_parent_id: parent_id, selected_id: task_id) }
  end

  def go_to_root
    -> { patch(current_parent_id: nil, selected_id: nil) }
  end

  def add_here(parent_id)
    ->(title, estimate) { create_task(title: title, estimate_pomodoros: estimate, parent_id: parent_id) }
  end

  def toggle_done(task)
    -> { update_task(task["id"], { done: !(task["done"] == true) }) }
  end

  def confirm_delete(task)
    -> {
      count = tree.subtree_ids(task).size - 1
      message = if count > 0
        "「#{task["title"]}」とサブタスク#{count}件を削除します。よろしいですか？"
      else
        "「#{task["title"]}」を削除します。よろしいですか？"
      end
      if JS.global.confirm(message).to_s == "true"
        was_selected = state[:selected_id] == task["id"]
        delete_task(task)
        patch(selected_id: nil) if was_selected
      end
    }
  end

  def handle_toggle_hide_done(_event)
    patch(hide_done: !state[:hide_done])
  end

  # ---------------------------------------------------------------
  # 右ペインのインライン編集（フィールドの値は DOM から直接読む。
  # フォーカス中の input には再描画の value が反映されないため、
  # 状態に持たず保存時に読むほうが素直）
  # ---------------------------------------------------------------
  def detail_field_id(task, name)
    "task-#{task["id"]}-#{name}"
  end

  def field_value(task, name)
    field = JS.document.getElementById(detail_field_id(task, name))
    field ? field[:value].to_s.strip : ""
  end

  def handle_title_blur(_event)
    task = tree.find(state[:selected_id])
    return unless task
    value = field_value(task, "title")
    return if value.empty? || value == task["title"]
    update_task(task["id"], title: value)
  end

  def handle_title_keydown(event)
    return unless event[:key].to_s == "Enter"
    event.preventDefault
    task = tree.find(state[:selected_id])
    return unless task
    field = JS.document.getElementById(detail_field_id(task, "title"))
    field.blur if field
  end

  def handle_estimate_change(_event)
    task = tree.find(state[:selected_id])
    return unless task
    raw = field_value(task, "estimate")
    update_task(task["id"], estimate_pomodoros: raw.empty? ? nil : raw.to_i)
  end

  def handle_starts_on_change(_event)
    task = tree.find(state[:selected_id])
    return unless task
    value = field_value(task, "starts_on")
    update_task(task["id"], starts_on: value.empty? ? nil : value)
  end

  def handle_due_on_change(_event)
    task = tree.find(state[:selected_id])
    return unless task
    value = field_value(task, "due_on")
    update_task(task["id"], due_on: value.empty? ? nil : value)
  end

  # ---------------------------------------------------------------
  # 表示用の下ごしらえ
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

  # 親をたどって根までの配列（根が先頭）
  def ancestors_of(parent_id, t)
    chain = []
    current = parent_id
    while current
      task = t.find(current)
      break unless task
      chain.unshift(task)
      current = task["parent_id"]
    end
    chain
  end

  # ---------------------------------------------------------------
  # 描画
  # ---------------------------------------------------------------
  def render
    t = tree

    # 構造が変わって今見ている階層が消えていたら根に戻す（安全策。state は書き換えない）
    current_parent_id = state[:current_parent_id]
    current_parent_id = nil if current_parent_id && !t.find(current_parent_id)

    selected = state[:selected_id] && t.find(state[:selected_id])
    # 選択中タスクは必ず「今見ている階層」の中のものだけを有効とする
    selected = nil if selected && selected["parent_id"] != current_parent_id

    crumbs = ancestors_of(current_parent_id, t)
    list = t.children_of_id(current_parent_id).select { |task| visible?(t, task) }

    div(class: "fmn-board") do
      div(class: "fmn-head") do
        h1(class: "fmn-head__title") { "タスク" }
        label(class: "fmn-head__option") do
          input(type: "checkbox", checked: state[:hide_done], onchange: :handle_toggle_hide_done)
          span { "完了したものを隠す" }
        end
      end

      div(class: "fmn-error-slot", role: "alert") do
        if state[:error]
          div(class: "fmn-error") do
            span { state[:error].to_s }
            button(class: "fmn-icon", onclick: :handle_dismiss_error, "aria-label": "閉じる") { "×" }
          end
        end
      end

      render_summary(t)

      if state[:loading]
        p(class: "fmn-empty") { "読み込み中…" }
      else
        div(class: "fmn-panes") do
          div(class: "fmn-pane fmn-pane--list") do
            render_breadcrumb(crumbs)

            component(NewTaskForm,
                      preserve: true,
                      form_id: "add-at-#{current_parent_id || "root"}",
                      placeholder: crumbs.empty? ? "やることを追加（Enter）" : "「#{crumbs.last["title"]}」に追加",
                      autofocus: false,
                      on_submit: add_here(current_parent_id))

            if list.empty?
              p(class: "fmn-empty") { "タスクがありません" }
            else
              ul(class: "fmn-tree") do
                list.each do |task|
                  render_list_row(t, task, selected && selected["id"], select_task(task["id"]))
                end
              end
            end
          end

          div(class: "fmn-pane fmn-pane--detail") do
            if selected
              render_detail(t, selected)
            else
              p(class: "fmn-empty") { "左の一覧からタスクを選んでください" }
            end
          end
        end
      end
    end
  end

  def handle_dismiss_error(_event)
    patch(error: nil)
  end

  def render_breadcrumb(crumbs)
    nav(class: "fmn-breadcrumb") do
      button(class: "fmn-crumb#{crumbs.empty? ? " is-current" : ""}", onclick: go_to_root) { "すべて" }
      crumbs.each do |task|
        span(class: "fmn-crumb-sep") { "›" }
        is_last = task["id"] == crumbs.last["id"]
        button(class: "fmn-crumb#{is_last ? " is-current" : ""}",
               onclick: go_to_breadcrumb(task["parent_id"], task["id"])) { task["title"] }
      end
    end
  end

  def render_list_row(t, task, selected_id, on_click)
    kind = t.kind_of(task)
    done = task["done"] == true
    size_text, progress_text = size_label(t, task, kind)
    period = period_of(task)
    child_count = t.children_of(task).size

    row_class = "fmn-row fmn-row--#{kind}"
    row_class += " is-done" if done
    row_class += " is-selected" if selected_id == task["id"]

    li(key: task["id"], class: "fmn-node") do
      div(class: row_class) do
        input(type: "checkbox", class: "fmn-check", checked: done,
              "aria-label": "完了", onchange: toggle_done(task))
        button(class: "fmn-title", onclick: on_click, title: "クリックで詳細を表示") { task["title"] }
        span(class: "fmn-badge fmn-badge--#{kind}") { TaskTree::KIND_LABELS[kind] }
        span(class: "fmn-meta") do
          span(class: "fmn-size") { size_text.to_s }
          span(class: "fmn-progress") { progress_text.to_s }
          if period
            span(class: "fmn-period#{period[1] ? " is-#{period[1]}" : ""}") do
              period[1] == :overdue ? "期限切れ #{period[0]}" : period[0]
            end
          end
        end
        if child_count > 0
          span(class: "fmn-chevron", title: "サブタスク #{child_count}件") { "#{child_count} ›" }
        end
      end
    end
  end

  def render_detail(t, task)
    kind = t.kind_of(task)
    done = task["done"] == true
    size_text, progress_text = size_label(t, task, kind)
    period = period_of(task)
    children = t.children_of(task).select { |child| visible?(t, child) }
    current_estimate = task["estimate_pomodoros"]

    div(class: "fmn-detail") do
      div(class: "fmn-detail__head") do
        input(type: "checkbox", class: "fmn-check", checked: done,
              "aria-label": "完了", onchange: toggle_done(task))
        input(type: "text", id: detail_field_id(task, "title"),
              class: "fmn-detail__title-input#{done ? " is-done" : ""}",
              value: task["title"], autocomplete: "off",
              onblur: :handle_title_blur, onkeydown: :handle_title_keydown)
        span(class: "fmn-badge fmn-badge--#{kind}") { TaskTree::KIND_LABELS[kind] }
      end

      div(class: "fmn-detail__fields") do
        div(class: "fmn-detail__field") do
          label(for: detail_field_id(task, "estimate"), class: "fmn-detail__label") { "見積もり" }
          tag("select", id: detail_field_id(task, "estimate"), class: "fmn-detail__input",
              onchange: :handle_estimate_change) do
            option(value: "", selected: current_estimate.nil?) { "未設定" }
            ESTIMATE_CHOICES.each do |n|
              option(value: n.to_s, selected: current_estimate.to_i == n) { "🍅 #{n}（#{n * 30}分）" }
            end
          end
        end
        div(class: "fmn-detail__field") do
          label(for: detail_field_id(task, "starts_on"), class: "fmn-detail__label") { "開始" }
          input(type: "date", id: detail_field_id(task, "starts_on"), value: task["starts_on"].to_s,
                class: "fmn-detail__input", onchange: :handle_starts_on_change)
        end
        div(class: "fmn-detail__field") do
          label(for: detail_field_id(task, "due_on"), class: "fmn-detail__label") { "期限" }
          input(type: "date", id: detail_field_id(task, "due_on"), value: task["due_on"].to_s,
                class: "fmn-detail__input", onchange: :handle_due_on_change)
        end
      end

      unless t.leaf?(task)
        p(class: "fmn-detail__note") do
          "サブタスクがあるので、サイズはサブタスクの見積もりの合計で表示されます。ここでの見積もりは最初の見立てとして残ります。"
        end
      end

      if kind == :big || (period && period[1])
        div(class: "fmn-detail__meta") do
          if kind == :big
            span { size_text.to_s }
            span { progress_text.to_s }
          end
          if period && period[1]
            span(class: "is-#{period[1]}") { period[1] == :overdue ? "期限切れ" : "今日が期限" }
          end
        end
      end

      div(class: "fmn-detail__actions") do
        button(class: "fmn-btn fmn-btn--danger", onclick: confirm_delete(task)) { "削除" }
      end

      div(class: "fmn-detail__children") do
        h3(class: "fmn-detail__subheading") { "サブタスク" }
        if children.empty?
          p(class: "fmn-empty fmn-empty--small") { "サブタスクはありません" }
        else
          ul(class: "fmn-tree") do
            children.each do |child|
              render_list_row(t, child, nil, drill_into(child["id"]))
            end
          end
        end

        component(NewTaskForm,
                  preserve: true,
                  form_id: "add-under-#{task["id"]}",
                  placeholder: "「#{task["title"]}」のサブタスク",
                  autofocus: false,
                  on_submit: add_here(task["id"]))
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
end
