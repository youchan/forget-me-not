module ForgetMeNot
  class WebSocket
    def initialize(url)
      @native = Native(`new WebSocket(#{url})`)
    end

    def on(event, &block)
      case event
      when :message
        @native.onmessage = Proc.new{|e| p e; block.call(e.data) }
      when :open
        @native.onopen = Proc.new{|e| block.call(e) }
      when :close
        @native.onclose = Proc.new{|e| block.call(e) }
      end
    end

    def send(msg)
      @native.write(msg)
    end
  end
end
