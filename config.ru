require 'bundler/setup'
Bundler.require(:default)

require_relative 'app'
require_relative 'app/base/server/store'
require_relative 'app/models/entry'
require_relative 'app/base/router'

map '/' do
  run ForgetMeNot::App.new(host: 'localhost')
end

map '/assets' do
  run ForgetMeNot::OPAL.sprockets
end

map '/api' do
  router = Router.new(Entry, TimeBox)
  run router.routes
end
