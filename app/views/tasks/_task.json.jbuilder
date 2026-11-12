json.extract! task, :id, :parent_id, :position, :title, :estimate_pomodoros,
              :starts_on, :due_on, :completed_at, :done, :created_at, :updated_at
json.tag_ids task.tag_ids
