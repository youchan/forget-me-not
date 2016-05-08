require 'browser/http'

class Store
  def initialize
    @tables = {}
  end

  def self.instance
    @instance ||= Store.new
  end

  def register(model_class)
    @tables[model_class] = {}
  end

  def [](model_class)
    @tables[model_class]
  end

  def save(model)
    table = @tables[model.class]
    Browser::HTTP.post("api/#{model.class.to_s}", model.to_json) do
      on :success do |res|
        table[model.id] = model.update(res.json)
        yield model if block_given?
      end

      on :failure do |res|
        puts ">> Error: #{res.error}"
        puts ">>>> save: #{model.inspect}"
      end
    end
  end

  def fetch(model_class, filter = nil,  &block)
    tables = @tables
    params = filter && ('?' + filter.map {|k,v| "#{k}=#{v}" }.join(?&))
    Browser::HTTP.get("api/#{model_class}#{params}") do
      on :success do |res|
        tables[model_class] = res.json.map {|value| [value[:id], model_class.new(value)] }.to_h
        yield tables[model_class].values if block_given?
      end

      on :failure do |res|
        puts ">> Error: #{res.error}"
        puts ">>>> save: #{model.inspect}"
      end
    end
  end
end
