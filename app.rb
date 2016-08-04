require 'opal'
require 'opal/sprockets'
require 'sinatra/base'
require "sinatra/activerecord"

module ForgetMeNot
  OPAL = Opal::Server.new {|s|
    s.append_path 'app'
    Opal.use_gem 'hyalite'
    Opal.paths.each {|path| s.append_path path }

    s.main = 'application'
  }

  class App < Sinatra::Base
    configure do
      set opal: ForgetMeNot::OPAL
    end

    get '/' do
      haml :index
    end

    get "/favicon.ico" do
    end
  end
end
