require 'date'
require_relative '../models/current_date'
require_relative '../models/time_period'
require_relative 'date_view'

class ScheduleView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  state :time_boxes, []
  state :now, TimePeriod.now

  def initialize
    @channel = ForgetMeNot::PushNotification.channel('forget_me_not')
    @current_date = CurrentDate.new(date: Date.today)
  end

  def component_did_mount
    fetch_time_boxes(Date.today)
    @current_date.on(:change, :date) do |date|
      fetch_time_boxes(date)
    end

    @channel.on_receive('BREAK') do |mesg|
      @current_date.date = Date.today
    end

    @channel.on_receive('START') do |mesg|
      @state.now = TimePeriod.new(mesg)
    end
  end

  def fetch_time_boxes(date)
    TimeBox.fetch(filter: {date: date}) do |time_boxes|
      set_state(time_boxes: time_boxes)
    end
  end

  def render
    time_boxes = @state.time_boxes.group_by(&:start_at)

    div({className: 'schedule'},
      DateView.el(date: @current_date),
      div({class: 'schedule-inner'},
        (TimePeriod.new(600)..TimePeriod.new(2300)).map do |tp|
          div({class: "koma #{tp.minute == 0 ? 'even' : 'odd'}"},
            [
              p(nil, tp.minute == 0 ? tp.to_s : ':30'),
              time_boxes[tp.to_i] && time_boxes[tp.to_i].map {|tb|
                div({class: "time-box pomodoro-#{tb.pomodoro} #{tb.status}"}, tb.entry.description)
              },
              (@state.now == tp ? div({class: 'line-time-current'}) : nil)
            ].compact.flatten
          )
        end
      )
    )
  end
end
