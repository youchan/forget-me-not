class ScheduleView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def render
    div({id:"schedule"},
      div({id:'schedule_inner'},
        (4..23).map {|i| div({className:"koma"}, "#{i}:00") }
      )
    )
  end
end
