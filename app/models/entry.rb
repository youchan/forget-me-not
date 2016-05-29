require_relative '../base/model'

class Entry < Model
  field :description, :string
  field :pomodoro, :int
  field :order, :int
  field :done, :boolean, default: false
end
