require 'securerandom'

class String
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end
end

class Model
  def initialize(fields)
    fields = fields.map{|k,v| [k.to_sym, v] }.to_h
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

  def self.fetch(filters = nil)
    store.fetch(self, filters) do |list|
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
      if type == :reference
        field_name = "#{name}_id"

        define_method(name) do
          id = @fields[field_name.to_sym]
          model_class = Object.const_get(name.camel_case)
          model_class[id]
        end

        define_method(name.to_s + "=") do |value|
          @fields[field_name.to_sym] = value.id
        end
      else
        field_name = name.to_s
      end

      define_method(field_name) do
        @fields[field_name.to_sym]
      end

      define_method(field_name + "=") do |value|
        unless type_validator(type).validate(value, name)
          raise 'type error'
        end
        @fields[field_name.to_sym] = value
      end
    end
  end

  def self.[](id)
    store.find(self, id)
  end

  def type_validator(type)
    case type
      when :string
        -> (value, name) { value.is_a? String }
      when :int
        -> (value, name) { value.is_a? Integer }
      when :reference
        -> (value, name) { valiedate_reference(value, name) }
    end
  end

  def valiedate_reference(value, name)
    return false unless value.is_a? String

    model_class = Object.const_get(name.camel_case)
    not model_class[value].nil?
  end

  def to_json(arg)
    @fields.merge(id: @guid).to_json
  end
end
