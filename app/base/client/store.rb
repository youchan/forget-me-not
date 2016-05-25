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

  def find(model_class, id)
    return self[model_class][id] if self[model_class][id]

    res = Browser::HTTP.get!("api/#{model_class.to_s}/#{id}")
    model = model_class.new(res.json)
    @tables[model_class][id] = model
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

  def fetch(model_class, filter: nil, order: nil, &block)
    tables = @tables
    params = filter && (?? + filter.map {|k,v| "#{k}=#{v}" }.join(?&))
    params = (params ? params + ?& : ??) + "order=#{[order].flatten.join(?,)}" if order
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

  def delete(mdoel_class)
    @tables[model_class] = {}
  end

  def max(model_class, field_name)
    res = Browser::HTTP.get!("api/#{model_class}?order=#{field_name}")
    model = model_class.new(res.json.last)
    model.fields[field_name]
  end
end
