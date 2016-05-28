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
          order = params.delete('order')&.split(?,)
          model.fetch(filter: params, order: order) do |data|
            json data, json_encorder: :to_json
          end
        end

        get "/#{resource_name}/:id" do
          json model[params[:id]]
        end

        post "/#{resource_name}" do
          data = JSON.parse(request.body.read)
          results = data.map do |model|
            instance = model_class.new model.map{|key, value| [key.to_sym, value] }.to_h
            instance.save
            instance
          end

          json results, json_encorder: :to_json
        end
      end
    end
  end
end
