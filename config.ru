require 'bundler/setup'
Bundler.require(:default)

require 'eventmachine'

require_relative 'app'
require_relative 'app/base/server/store'
require_relative 'app/scheduler'
require_relative 'app/periodic_timer'
require_relative 'app/models/entry'
require_relative 'app/models/time_box'
require_relative 'app/base/router'

EventMachine.run do
  scheduler = ForgetMeNot::Scheduler.new
  scheduler.reschedule(TimePeriod.now)

  ForgetMeNot::PeriodicTimer.run do
    on(:start) { scheduler.reschedule(TimePeriod.now) }
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
      router = Router.new(Entry, TimeBox)
      run router.routes
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
