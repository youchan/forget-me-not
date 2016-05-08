require 'date'

class ScheduleView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def initial_state
    date = Date.today
    TimeBox.fetch(date: date) {|time_boxes| set_state(time_boxes: time_boxes) }
    { time_boxes: [] }
  end

  def render
    puts @state[:time_boxes].to_json
    time_boxes = @state[:time_boxes].group_by(&:start_at)

    div({className: 'schedule'},
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
