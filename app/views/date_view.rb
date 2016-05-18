class DateView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def initial_state
    { date: @props[:date] }
  end

  def prev_day
    @state[:date].date = @state[:date].date - 1
    set_state(date: @state[:date])
  end

  def next_day
    @state[:date].date = @state[:date].date + 1
    set_state(date: @state[:date])
  end

  def render
    div({className: 'date-control'},
      p(nil, a({className: 'prev-day', onClick: -> { self.prev_day }}, '<<')),
      p(nil, @state[:date].date.to_s),
      p(nil, a({className: 'next-day', onClick: -> { self.next_day }}, '>>'))
    )
  end
end
