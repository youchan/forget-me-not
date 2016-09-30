require 'bundler/setup'
Bundler.require(:default)

require 'eventmachine'
require 'menilite'

require_relative 'app'
require_relative 'app/scheduler'
require_relative 'app/periodic_timer'
require_relative 'app/notification'

EventMachine.run do
  scheduler = ForgetMeNot::Scheduler.new
  scheduler.reschedule(TimePeriod.now)

  notification = Notification.new

  ForgetMeNot::PeriodicTimer.run do
    on(:start) { scheduler.reschedule(TimePeriod.now) }

    on(:rest) do
      begin
        notification.send("25分働きました。休憩しましょう。")
      rescue => e
        puts e.message
        puts e.backtrace
      end
    end

    on(:start) do
      begin
        notification.send("仕事をはじめてください。")
      rescue => e
        puts e.message
        puts e.backtrace
      end
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

    map '/line_bot' do
      run notification.routes
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
