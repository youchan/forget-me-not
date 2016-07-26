class Entry < Menilite::Model
  field :description, :string
  field :pomodoro, :int
  field :order, :int
  field :done, :boolean, default: false
end
