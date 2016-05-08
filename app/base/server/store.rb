class Store
  DEFAULT_DB_DIR = './.store'

  def initialize(db_dir = DEFAULT_DB_DIR)
    @tables = {}
    @guid = SecureRandom.uuid
    @db_dir = db_dir
    Dir.mkdir(@db_dir) unless Dir.exist?(@db_dir)
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

    File.open(@db_dir + "/#{model.class}.db", "w") do |file|
      file.write @tables[model.class].values.to_json
    end

    yield model if block_given?
  end

  def fetch(model_class, filter = nil)
    File.open(@db_dir + "/#{model_class}.db") do |file|
      records = JSON.parse(file.read)
      records.select! {|r| filter.all? {|k,v| r[k] == v } } if filter
      @tables[model_class] = records.map {|m| [m["id"], model_class.new(m)] }.to_h
    end

    yield @tables[model_class].values || [] if block_given?
  end
end


