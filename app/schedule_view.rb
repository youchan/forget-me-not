class ScheduleView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def render
    div({className: 'schedule'},
      div({className: 'schedule-inner'},
        ('04'..'23').map {|i| div({className: 'koma'}, "#{i}:00") }
      )
    )
  end
end
