require 'delegate'

module Hyalite
  module Sortable
    def self.create
      _config = Config.new
      yield _config

      Class.new {
        include Component
        include Component::ShortHand
        include Sortable

        def self.config=(config)
          @config = config
        end

        def self.config
          @config
        end
      }.tap{|cl| cl.config = _config }
    end

    def initialize
      @config = self.class.config
    end

    def render
      @config.wrap.el({className: 'hyalite-sortable'},
        @props[:collection].sort_by(&@config.sort).map {|model| @config.component.el({@config.prop_key => model}.merge(@props)) }
      )
    end

    class Config
      attr_accessor :wrap, :component, :prop_key
      attr_reader :sort

      def sort_by(field_name = nil, &block)
        if field_name
          if block
            @sort = -> (model) { block.call(model.fields[field_name]) }
          else
            @sort = -> (model) { model.fields[field_name] }
          end
        else
          @sort = block
        end
      end
    end
  end
end
