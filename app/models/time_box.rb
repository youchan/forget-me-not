require 'menilite/model'

class TimeBox < Menilite::Model
  field :entry, :reference
  field :pomodoro, :int
  field :start_at, :int
  field :date, :date
  field :status, :int

  def start_oclock
    self.start_at / 100
  end

  def start_min
    self.start_at % 100
  end

  def status=(v)
    int_value = 0
    case v
    when :scheduled
      int_value = 0
    when :confirm
      int_value = 1
    when :done
      int_value = 2
    end

    super int_value
  end

  def status
    %i(scheduled confirm done)[super]
  end
end
