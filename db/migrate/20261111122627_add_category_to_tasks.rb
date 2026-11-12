class AddCategoryToTasks < ActiveRecord::Migration[8.1]
  def change
    add_reference :tasks, :category, null: true, foreign_key: true
  end
end
