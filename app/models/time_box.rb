require 'menilite/model'
require_relative './entry.rb'

class TimeBox < Menilite::Model
  field :entry, :reference, class: ::Entry
  field :pomodoro, :int
  field :start_at, :int
  field :date, :date
  field :status, enum: %i(scheduled confirm done)

  def start_oclock
    self.start_at / 100
  end

  def start_min
    self.start_at % 100
  end
end
