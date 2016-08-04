class CreateTableEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.string :guid
      t.string :description
      t.integer :pomodoro
      t.integer :order
      t.boolean :done, null: false, default: false
    end
  end
end
