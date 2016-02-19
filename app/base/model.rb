class Model
  def initialize(fields)
    @fields = {}.merge(fields)
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

  def type_validator(type)
    case type
      when :string
        -> (value) { value.is_a? String }
      when :int
        -> (value) { value.is_a? Integer }
    end
  end
end
