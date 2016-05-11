class TimePeriod
  attr_reader :hour, :minute

  def initialize(time, interval=30)
    self.time = time
    @interval = interval
  end

  def succ
    min = @minute + @interval
    hour = @hour + (min / 60)
    minute = min % 60
    TimePeriod.new(hour * 100 + minute, @interval)
  end

  def <=>(other)
    self.to_i <=> other.to_i
  end

  def to_s
    "#{@hour.to_s.rjust(2, ?0)}:#{@minute.to_s.rjust(2, ?0)}"
  end

  def to_i
    @hour * 100 + @minute
  end

  def time=(time)
    case time
    when String
      raise "parse error: #{time}"  unless /\A(\d{2}):(\d{2})\z/ =~ time
      @hour = $1.to_i
      @minute = $2.to_i
    when Integer
      @hour = time / 100
      @minute = time % 100
    end
  end
end