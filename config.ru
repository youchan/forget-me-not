require 'bundler/setup'
Bundler.require(:default)

require File.dirname(__FILE__) + '/app.rb'

map '/' do
  run ForgetMeNot::App.new(host: 'localhost')
end

map '/assets' do
  run ForgetMeNot::OPAL.sprockets
end

