require_relative 'schedule_view'

class TodoView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def initial_state
    { entries: [] }
  end

  def unscheduled_entries
    li(nil,
      @state[:entries].reject{|entry| entry.scheduled}.map{|entry| DescriptionView.el({entry: entry})}
    )
  end

  def scheduled_entries
    li(nil,
      @state[:entries].select{|entry| entry.scheduled}.map{|entry| DescriptionView.el({entry: entry})}
    )
  end

  def render
    div(nil,
      form({className:"form-horizontal"},
        input(type:"text"),
        button({className:"btn", onclick: -> { add_entry } }, i({className:"icon-plus"}, "Add"))
      ),
      div({className:"entries"},
        div(nil,
          h3(nil, a({href:"#"}, "未スケジュール")),
          div({className:"acc_content"},
            ol({className:"unscheduled selectable"}, unscheduled_entries))
        ),
        div(nil,
          h3(nil, a({href:"#"}, "スケジュール済")),
          div({className:"acc_content"},
            ol({className:"scheduled selectable"}, scheduled_entries))
        ),
      ),
      ScheduleView.el(nil),
      br(className: 'clears')
    )
  end
end

class DescriptionView
  def render
    div({className:"description"}, @props[:entry].description, div({className:"period"}, @props[:entry].period))
  end
end
