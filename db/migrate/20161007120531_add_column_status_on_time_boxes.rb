class AddColumnStatusOnTimeBoxes < ActiveRecord::Migration
  def change
    add_column :time_boxes, :integer, null: false, default: 0
  end
end
