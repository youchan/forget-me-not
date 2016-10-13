class WSWrapper
  def initialize(url)
    @ws = Browser::Socket.new(url)
  end

  def on(event, &block)
    if event == :message
      @ws.on(event) {|message| block.call(message.data) }
    else
      @ws.on(event, &block)
    end
  end

  def send(msg)
    @ws.write(msg)
  end
end
