# Todo（タイトルと完了フラグだけ）を、階層・見積もり・期間を持つ Task に作り替える。
#
# - todos テーブルを tasks にリネーム
# - parent_id で無制限の階層を表現（nil ならルートのタスク）
# - estimate_pomodoros: 見積もり（1ポモドーロ = 30分）
# - starts_on / due_on: 開始日・期限（どちらも任意）
# - done(boolean) を completed_at(datetime) に置き換え
class ConvertTodosToTasks < ActiveRecord::Migration[8.1]
  def up
    rename_table :todos, :tasks

    change_table :tasks do |t|
      t.references :parent, foreign_key: { to_table: :tasks }
      t.integer :position, null: false, default: 0
      t.integer :estimate_pomodoros
      t.date :starts_on
      t.date :due_on
      t.datetime :completed_at
    end

    execute <<~SQL
      UPDATE tasks SET completed_at = updated_at WHERE done = 1
    SQL
    # 既存の Todo は作成順に並べておく
    execute <<~SQL
      UPDATE tasks SET position = id
    SQL

    remove_column :tasks, :done
    add_index :tasks, [ :user_id, :parent_id, :position ]
  end

  def down
    remove_index :tasks, [ :user_id, :parent_id, :position ]
    add_column :tasks, :done, :boolean, null: false, default: false
    execute <<~SQL
      UPDATE tasks SET done = 1 WHERE completed_at IS NOT NULL
    SQL

    # 階層は Todo では表現できないので、親子関係は失われる（行は残る）
    change_table :tasks do |t|
      t.remove_references :parent, foreign_key: { to_table: :tasks }
      t.remove :position, :estimate_pomodoros, :starts_on, :due_on, :completed_at
    end

    rename_table :tasks, :todos
  end
end
