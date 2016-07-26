require 'eventmachine'

EventMachine.run do
  n = 0
  timer = EventMachine::PeriodicTimer.new(1) do
    sleep(3)
    puts "the time is #{Time.now}"
    EventMachine.stop if (n+=1) > 5
  end
end
