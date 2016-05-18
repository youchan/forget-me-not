require 'date'
require_relative '../models/current_date'
require_relative 'date_view'

class ScheduleView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def initial_state
    fetch_time_boxes(Date.today)
    { time_boxes: [] }
  end

  def fetch_time_boxes(date)
    TimeBox.fetch(filter: {date: date}) do |time_boxes|
      set_state(time_boxes: time_boxes)
    end
  end

  def render
    time_boxes = @state[:time_boxes].group_by(&:start_at)

    current_date = CurrentDate.new(date: Date.today)
    current_date.on(:change, :date) do |date|
      fetch_time_boxes(date)
    end

    div({className: 'schedule'},
      DateView.el(date: current_date),
      div({className: 'schedule-inner'},
        ('06'..'23').map {|i|
          [ div({className: 'koma even'}, p(nil, "#{i}:00"),
            time_boxes["#{i}:00"] && time_boxes["#{i}:00"].map{|tb| div({className: "time-box pomodoro-#{tb.pomodoro}"}, tb.entry.description)}
          ),
          div({className: 'koma odd'}, p(nil, ":30"),
            time_boxes["#{i}:30"] && time_boxes["#{i}:30"].map{|tb| div({className: "time-box pomodoro-#{tb.pomodoro}"}, tb.entry.description)}
          )]
        }.flatten
      ),
    )
  end
end
