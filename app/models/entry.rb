require_relative '../base/model'

class Entry < Model
  field :description, :string
  field :pomodoro, :int
end
