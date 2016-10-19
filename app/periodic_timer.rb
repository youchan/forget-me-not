module ForgetMeNot
  class PeriodicTimer
    def initialize
      @handlers = {}
    end

    def self.on(event, &block)
      @singleton_instance ||= PeriodicTimer.new
      @singleton_instance.on(event, &block)
    end

    def on(event, &block)
      @handlers[event] ||= []
      @handlers[event] << block
    end

    def self.run(&block)
      @singleton_instance ||= PeriodicTimer.new
      @singleton_instance.run &block
    end

    def run(&block)
      self.instance_eval(&block) if block_given?

      last_processed_at = nil
      EventMachine.add_periodic_timer(5) do
        SpeedUp.next if defined? SpeedUp

        now = Time.now
        next if last_processed_at && last_processed_at.hour == now.hour && last_processed_at.min == now.min

        case now.min
        when 25, 55
          @handlers[:break]&.each {|handler| handler.call }
        when 00, 30
          @handlers[:start]&.each {|handler| handler.call }
        end
      end
    end
  end
end
