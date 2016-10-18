class TimePeriod
  include Comparable

  attr_reader :hour, :minute

  def initialize(time, interval=30)
    self.time = time
    @interval = interval
  end

  def succ
    min = @minute + @interval
    hour = (@hour + (min / 60)).floor
    minute = min % 60
    TimePeriod.new(hour * 100 + minute, @interval)
  end

  def next(step=1)
    TimePeriod.from_minutes(total_minutes + @interval * step, @interval)
  end

  def -(other)
    ((self.total_minutes - other.total_minutes) / @interval).floor
  end

  def total_minutes
    @hour * 60 + @minute
  end

  def self.from_minutes(minutes, interval=30)
    hour = (minutes / 60).floor
    minute = minutes % 60
    TimePeriod.new(hour * 100 + minute, interval)
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
      raise ArgumentError.new("parse error: #{time}")  unless /\A(\d{2}):?(\d{2})\z/ =~ time
      @hour = $1.to_i
      @minute = $2.to_i
    when Integer
      @hour = (time / 100).floor
      @minute = time % 100
    end
  end

  def self.now(interval = 30)
    now = Time.now
    TimePeriod.from_minutes(((now.hour * 60 + now.min) / interval).floor * interval, interval)
  end

  def to(dest)
    start = self.to_i
    last = dest.to_i
    start.step(last, @interval).map{|i| TimePeriod.new(i) }.to_enum
  end
end
