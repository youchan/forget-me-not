class ContextMenu
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def self.create
    _config = Config.new
    yield _config

    Class.new {
      include Component
      include Component::ShortHand
      include ContextMenu

      def self.config=(config)
        @config = config
      end

      def self.config
        @config
      end
    }.tap{|cl| cl.config = _config }
  end

  def handle_item_click(event)
    target = event.target
    until target.data['label']
      target = target.parent
    end
    @props[:onSelect].call(target.data["label"]) if @props[:onSelect]
  end

  def render
    div({ className: 'context-menu' + (@props[:visible] ? ' visible' : ''), style: { top: "#{@props[:position][:y]}px", left: "#{@props[:position][:x]}px" } },
      ul(nil,
        @props[:options].map {|k, v|
          li({ "data-label": k, onClick: self.method(:handle_item_click) },
            @props[:cellComponent] ? @props[:cellComponent].el(value: v) : v)
        }
      )
    )
  end

  class Config
  end
end
