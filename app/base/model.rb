require 'securerandom'

class Model
  def initialize(fields)
    @guid = fields.delete(:id) || SecureRandom.uuid
    @fields = {}.merge(fields)
  end

  def id
    @guid
  end

  def save(&block)
    self.class.store.save(self, &block)
  end

  def update(data)
    case data
    when self.class
      @fields.merge(data.fields)
    when Hash
      @fields.merge(data)
    when String
      @fields.merge(JSON.parse(json))
    end
  end

  def self.fetch_all
    store.fetch(self) do |list|
      yield list if block_given?
    end
  end

  def self.store
    Store.instance
  end

  def self.inherited(child)
    store.register(child)
  end

  def self.field(name, type, params = {})
    self.instance_eval do
      define_method(name) do
        @fields[name]
      end

      define_method(name.to_s + "=") do |value|
        unless type_validator(type).validate(value)
          raise 'type error'
        end
        @fields[name] = value
      end
    end
  end

  def self.[](id)
    store[self][id]
  end

  def type_validator(type)
    case type
      when :string
        -> (value) { value.is_a? String }
      when :int
        -> (value) { value.is_a? Integer }
    end
  end

  def to_json(arg)
    @fields.merge(id: @guid).to_json
  end
end
