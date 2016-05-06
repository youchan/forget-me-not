require_relative '../base/model'

class TimeBox < Model
  field :entry_id, :string
  field :pomodoro, :int
  field :start_at, :int
  field :date, :date

  def start_oclock
    self.start_at / 100
  end

  def start_min
    self.start_at % 100
  end
end
