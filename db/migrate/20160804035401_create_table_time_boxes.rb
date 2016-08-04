class CreateTableTimeBoxes < ActiveRecord::Migration
  def change
    create_table :time_boxes do |t|
      t.string :guid
      t.string :entry_guid
      t.integer :pomodoro
      t.integer :start_at
      t.date :date
    end
  end
end
