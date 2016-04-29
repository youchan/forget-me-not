require 'sinatra/base'
require 'sinatra/json'
require 'json'

class Router
  def initialize(*models)
    @models = models
  end

  def routes
    models = @models
    Sinatra.new do
      models.each do |model|
        resource_name = model.to_s
        model_class = model
        get "/#{resource_name}" do
          model.fetch_all do |data|
            json data, json_encorder: :to_json
          end
        end

        get "/#{resource_name}/:id" do
          json model[params[:id]]
        end

        post "/#{resource_name}" do
          data = JSON.parse(request.body.read)
          instance = model_class.new data.map{|key, value| [key.to_sym, value] }.to_h
          instance.save
          json data
        end
      end
    end
  end
end
