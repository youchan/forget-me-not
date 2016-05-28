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

  def handle_item_click(el)
    set_state(visible: false)
    @props[:onSelect].call(el.data["label"]) if @props[:onSelect]
  end

  def render
    div({ className: 'context-menu' + (@props[:visible] ? ' visible' : ''), style: { top: "#{@props[:position][:y]}px", left: "#{@props[:position][:x]}px" } },
      ul(nil,
        @props[:options].map {|k, v| li({ "data-label": k, onClick: -> (evt) { handle_item_click(evt.target) } }, v) }
      )
    )
  end

  class Config
  end
end
