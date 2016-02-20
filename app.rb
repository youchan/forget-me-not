require 'opal'
require 'opal/sprockets'
require 'sinatra/base'

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
  end
end
