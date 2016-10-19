class SpeedUp
  def self.start(start = Time.parse('10:00'))
    @start = start
    Timecop.travel(start)
  end

  def self.next
    now = Time.now

    min1 = now.min % 10
    min2 = now.min / 10

    if min1 < 5
      now = Time.parse("#{now.hour}:#{min2}5", now)
    elsif min2 < 5
      now = Time.parse("#{now.hour}:#{min2 + 1}0", now)
    else
      now = Time.parse("#{now.hour + 1}:00", now)
    end

    if now.hour >= 23
      now = @start
    end

    p now

    Timecop.travel(now)
  end
end
