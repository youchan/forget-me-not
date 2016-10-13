class WSWrapper
  def initialize(ws)
    @ws = ws
  end

  def on(event, &block)
    case event
    when :open
      @ws.onopen(&block)
    when :message
      @ws.onmessage(&block)
    when :close
      @ws.onclose(&block)
    end
  end

  def send(msg)
    @ws.send(msg)
  end
end
