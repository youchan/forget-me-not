# /tasks.json が返すフラットなタスクの配列（キーは文字列）を木として扱うためのクラス。
#
# 分類（kind）は保存せず、ここで導出する:
#   :big         子タスクを持つ「大きなタスク」
#   :todo        子がなく、見積もりが QUICK_POMODOROS 以下の「すぐ終わる todo」
#   :split       子がなく、見積もりが QUICK_POMODOROS を超えた「分割したほうがいい」タスク
#   :unestimated 子がなく、見積もりが未設定
#
# PicoRuby には sum / group_by / sort_by / Set が無いので、each と inject で書いている。
class TaskTree
  QUICK_POMODOROS = 2

  KIND_LABELS = {
    big: "大きなタスク",
    todo: "すぐ終わる",
    split: "分割しよう",
    unestimated: "見積もりなし"
  }

  attr_reader :tasks

  def initialize(tasks)
    @tasks = tasks
    @by_id = {}
    @children = {}
    tasks.each do |t|
      @by_id[t["id"]] = t
      key = t["parent_id"]
      @children[key] = [] unless @children[key]
      @children[key] << t
    end
    @children.each do |_key, list|
      list.sort! { |a, b| compare_position(a, b) }
    end
  end

  def find(id)
    @by_id[id]
  end

  def roots
    @children[nil] || []
  end

  def children_of(task)
    @children[task["id"]] || []
  end

  def leaf?(task)
    children_of(task).empty?
  end

  def done?(task)
    task["done"] == true
  end

  def kind_of(task)
    return :big unless leaf?(task)
    estimate = task["estimate_pomodoros"]
    return :unestimated if estimate.nil?
    estimate.to_i > QUICK_POMODOROS ? :split : :todo
  end

  # 子孫の葉タスク（自分が葉なら自分）
  def leaves_under(task)
    return [ task ] if leaf?(task)
    result = []
    children_of(task).each do |child|
      leaves_under(child).each { |leaf| result << leaf }
    end
    result
  end

  # 大きなタスクのサイズ。葉の見積もりを合計する
  #   { total:, remaining:, unestimated:, done_count:, leaf_count: }
  def rollup(task)
    leaves = leaves_under(task)
    total = 0
    remaining = 0
    unestimated = 0
    done_count = 0
    leaves.each do |leaf|
      estimate = leaf["estimate_pomodoros"]
      leaf_done = done?(leaf) || done?(task)
      done_count += 1 if leaf_done
      if estimate.nil?
        unestimated += 1 unless leaf_done
      else
        total += estimate.to_i
        remaining += estimate.to_i unless leaf_done
      end
    end
    { total: total, remaining: remaining, unestimated: unestimated,
      done_count: done_count, leaf_count: leaves.size }
  end

  # 自分を含む子孫の id
  def subtree_ids(task)
    ids = [ task["id"] ]
    children_of(task).each do |child|
      subtree_ids(child).each { |id| ids << id }
    end
    ids
  end

  # 未完了の葉タスクを分類ごとに数える（画面上部のサマリー用）
  def open_leaf_counts
    counts = { todo: 0, split: 0, unestimated: 0, big: 0 }
    @tasks.each do |t|
      next if done?(t)
      counts[kind_of(t)] += 1
    end
    counts
  end

  private

  def compare_position(a, b)
    cmp = a["position"].to_i <=> b["position"].to_i
    cmp == 0 ? (a["id"].to_i <=> b["id"].to_i) : cmp
  end
end
