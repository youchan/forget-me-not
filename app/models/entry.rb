class Entry
  attr_accessor :description, :pomodoro

  def initialize(description, pomodoro = 1)
    @description = description
    @pomodoro = pomodoro
  end

  def scheduled?
    false
  end
end
