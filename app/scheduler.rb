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

      entries = Entry.fetch(filter: { done: false }, order: :order)

      time_boxes = entries.each_with_object([]) do |entry, time_boxes|
        duration = @scope.end - at
        pomodoro = entry.pomodoro
        while duration < pomodoro
          time_boxes << TimeBox.new(entry_id: entry.id, pomodoro: duration, date: date, start_at: at.to_i)
          at = @scope.begin
          date = date.next_day
          pomodoro -= duration
          duration = @scope.end - @scope.begin
        end
        time_boxes << TimeBox.new(entry_id: entry.id, pomodoro: pomodoro, date: date, start_at: at.to_i)
        at = at.next(pomodoro)
      end

      TimeBox.save(time_boxes)
    end

    def break(at, date = Date.today)
      time_box = TimeBox.find(date: date, start_at: at.to_i, status: :scheduled)
      if time_box
        confirm = TimeBox.find(entry_id: time_box.entry.id, status: :confirm)
        if confirm
          confirm.update(date: date, start_at: at.to_i, pomodoro: 30)
        else
          TimeBox.create(entry_id: time_box.entry.id, date: date, start_at: at.to_i, pomodoro: 30, status: :confirm)
        end
      end
    rescue => e
      pp e
      raise
    end

    def offset_schedule

    end
  end
end
