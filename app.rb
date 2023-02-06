require 'opal'
require 'opal/sprockets'
require 'sinatra/base'
require "sinatra/activerecord"
require_relative 'app/server/ws_wrapper'

module ForgetMeNot
  Opal.use_gem 'hyalite'
  OPAL = Opal::Sprockets::Server.new {|s|
    s.append_path 'app'
    # Opal.paths.each {|path| s.append_path path }

    s.main = 'application'
  }

  class App < Sinatra::Base
    configure do
      set opal: ForgetMeNot::OPAL
    end

    get '/' do
      haml :index
    end

    get '/push_notification/start/:channel' do
      request.websocket do |ws|
        channel = ForgetMeNot::PushNotification.channel(params[:channel])
        channel.connect(ForgetMeNot::WebSocket.new(ws))
      end
    end

    get "/favicon.ico" do
    end
  end
end
