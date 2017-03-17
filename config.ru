require 'bundler/setup'

if ENV['SPEED_UP']
  Bundler.require(:default, :speed_up)
  require_relative 'app/speed_up'
  SpeedUp.start
else
  Bundler.require(:default)
end

require 'eventmachine'
require 'menilite'

require_relative 'app'
require_relative 'app/scheduler'
require_relative 'app/periodic_timer'
require_relative 'app/push_notification'

EventMachine.run do
  scheduler = ForgetMeNot::Scheduler.new(TimePeriod.new(1100)..TimePeriod.new(1900))
  scheduler.reschedule(TimePeriod.now)
  channel = ForgetMeNot::PushNotification.channel('forget_me_not')

  ForgetMeNot::PeriodicTimer.run do
    on(:start) do
      now = TimePeriod.now
      scheduler.reschedule(now)
      channel.send('START', now.to_s)
    end

    on(:break) do
      now = TimePeriod.now
      scheduler.break(now)
      channel.send('BREAK', now.to_s)
    end
  end

  app = Rack::Builder.app do
    map '/' do
      run ForgetMeNot::App.new(host: 'localhost')
    end

    map '/assets' do
      run ForgetMeNot::OPAL.sprockets
    end

    map '/__OPAL_SOURCE_MAPS__' do
      run Opal::SourceMapServer.new(ForgetMeNot::OPAL.sprockets, '/__OPAL_SOURCE_MAPS__')
    end

    map '/api' do
      router = Menilite::Router.new
      run router.routes(settings)
    end
  end

  Rack::Server.start({
    app:    app,
    server: 'thin',
    Host:   '0.0.0.0',
    Port:   9292,
    signals: false,
  })
end
