module Hyalite
  module ProxyComponent
    def self.create(&block)
      Class.new {
        include Component
        include Component::ShortHand

        def self.render_proc=(proc)
          @render_proc = proc
        end

        def self.render_proc
          @render_proc
        end

        def render
          self.instance_exec(@props, &self.class.render_proc)
        end
      }.tap{|cl| cl.render_proc = block }
    end
  end

  def self.fn(&block)
    ProxyComponent.create(&block)
  end
end
