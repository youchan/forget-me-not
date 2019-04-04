class AddColumnStatusOnTimeBoxes < ActiveRecord::Migration[5.2]
  def change
    add_column :time_boxes, :status, :integer, null: false, default: 0
  end
end
