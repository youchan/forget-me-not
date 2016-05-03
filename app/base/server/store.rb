class Store
  def initialize
    @tables = {}
    @guid = SecureRandom.uuid
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
    @tables[model.class][model.id] = model
    yield model if block_given?
  end

  def fetch(model_class)
    yield @tables[model_class].values || [] if block_given?
  end
end


