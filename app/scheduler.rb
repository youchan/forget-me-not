require 'date'
require_relative 'models/time_period'
require_relative 'models/time_box'
require_relative 'models/entry'

module ForgetMeNot
  class Scheduler
    attr_reader :scope

    def initialize(scope=(TimePeriod.new(1000)..TimePeriod.new(1900)))
      @scope = scope
    end

    def reschedule(start_at, start_date=Date.today)
      TimeBox.delete_all

      date = start_date
      at = start_at
      unless @scope.cover?(at)
        date = date.next_day if @scope.end - at < 0
        at = @scope.begin
      end

      Entry.fetch(order: :order) do |entries|
        entries.each do |entry|
          duration = @scope.end - at
          pomodoro = entry.pomodoro
          while duration < pomodoro
            TimeBox.create(entry_id: entry.id, pomodoro: duration, date: date, start_at: at.to_s)
            at = @scope.begin
            date = date.next_day
            pomodoro -= duration
            duration = @scope.end - @scope.begin
          end
          TimeBox.create(entry_id: entry.id, pomodoro: pomodoro, date: date, start_at: at.to_s)
          at = at.next(pomodoro)
        end
      end
    end

    def offset_schedule

    end
  end
end
