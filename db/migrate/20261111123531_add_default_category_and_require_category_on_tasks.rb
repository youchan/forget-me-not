class AddDefaultCategoryAndRequireCategoryOnTasks < ActiveRecord::Migration[8.1]
  def up
    add_column :categories, :is_default, :boolean, default: false, null: false

    say_with_time "Creating a default category for users with uncategorized tasks" do
      execute <<~SQL
        INSERT INTO categories (user_id, name, position, is_default, created_at, updated_at)
        SELECT DISTINCT tasks.user_id, 'default', 0, 1, datetime('now'), datetime('now')
        FROM tasks
        WHERE tasks.category_id IS NULL
        AND NOT EXISTS (
          SELECT 1 FROM categories c2 WHERE c2.user_id = tasks.user_id AND c2.name = 'default'
        )
      SQL

      # 念のため、既に同名の "default" カテゴリがあった場合はそれを既定カテゴリ扱いにする
      execute <<~SQL
        UPDATE categories SET is_default = 1
        WHERE name = 'default' AND user_id IN (SELECT DISTINCT user_id FROM tasks WHERE category_id IS NULL)
      SQL
    end

    say_with_time "Moving uncategorized tasks into the default category" do
      execute <<~SQL
        UPDATE tasks
        SET category_id = (
          SELECT categories.id FROM categories
          WHERE categories.user_id = tasks.user_id AND categories.is_default = 1
        )
        WHERE tasks.category_id IS NULL
      SQL
    end

    change_column_null :tasks, :category_id, false

    add_index :categories, :user_id, unique: true, where: "is_default = 1",
      name: "index_categories_on_user_id_when_default"
  end

  def down
    remove_index :categories, name: "index_categories_on_user_id_when_default"
    change_column_null :tasks, :category_id, true
    remove_column :categories, :is_default
  end
end
