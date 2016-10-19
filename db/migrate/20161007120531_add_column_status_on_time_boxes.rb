class AddColumnStatusOnTimeBoxes < ActiveRecord::Migration
  def change
    add_column :time_boxes, :status, :integer, null: false, default: 0
  end
end
