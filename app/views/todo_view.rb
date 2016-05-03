require_relative 'schedule_view'
require_relative '../models/entry'

class TodoView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def initial_state
    Entry.fetch_all {|entries| set_state(entries: entries) }
    { new_todo: '', entries: [] }
  end

  def add_entry
    entry = Entry.new(description: @state[:new_todo], pomodoro: 1)
    entry.save do
      @state[:entries] << entry
      @state[:new_todo] = ''
      set_state(@state)
    end
  end

  def handle_change(event)
    set_state(new_todo: event.target.value)
  end

  def handle_input_on_keydown(event)
    if event.code == 13
      add_entry
    end
  end

  def unscheduled_entries
    li(nil,
      @state[:entries].reject{|entry| entry.scheduled?}.map{|entry| DescriptionView.el({entry: entry})}
    )
  end

  def scheduled_entries
    li(nil,
      @state[:entries].select{|entry| entry.scheduled?}.map{|entry| DescriptionView.el({entry: entry})}
    )
  end

  def render
    div(nil,
      div({className: 'todo-view'},
        label({'for': 'new-todo'}, 'Todo:'),
        input(
          id: 'new-todo',
          className: 'new-todo',
          type: 'text',
          onKeyDown: -> (event) { handle_input_on_keydown(event) },
          onChange: -> (event) { handle_change(event) },
          value: @state[:new_todo]),
        div({className: 'entries'},
          div(nil,
            h3(nil, a({href:"#"}, "未スケジュール")),
            div({className:"acc-content"},
              ol({className:"unscheduled selectable"}, unscheduled_entries))
          ),
          div(nil,
            h3(nil, a({href:"#"}, "スケジュール済")),
            div({className:"acc-content"},
              ol({className:"scheduled selectable"}, scheduled_entries))
          )
        ),
      ),
      ScheduleView.el(nil),
      br(className: 'clears')
    )
  end
end

class DescriptionView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def render
    div({className:"description"},
      @props[:entry].description,
      span({className: 'pomodoro'},
        @props[:entry].pomodoro.times.map{ img(className: 'pomodoro', src: 'images/pomodoro.png') }
      )
    )
  end
end
