if RUBY_ENGINE == 'opal'
  require 'browser/socket'
  require 'browser/location'
  require_relative 'client/ws_wrapper'
end

module ForgetMeNot
  module PushNotification
    def self.channel(key)
      @channel ||= {}
      @channel[key] ||= Channel.new(key)
    end

    class Channel
      attr_reader :name

      def initialize(name, &block)
        @name = name
        @sockets = []
        @listeners = {}
      end

      if RUBY_ENGINE == 'opal'
        def connect(&block)
          socket = WSWrapper.new("ws://#{$window.location.host}/push_notification/start/#{name}")
          setup_connection(socket, &block)
        end
      else
        def connect(socket, &block)
          setup_connection(socket, &block)
        end
      end

      def send(command, message)
        @sockets.each do |sock|
          sock.send("#{command}: #{message}")
        end
      end

      def on_receive(command, &block)
        (@listeners[command] ||= []) << block
      end

      private

      def setup_connection(socket, &block)
        @sockets << socket
        setup_listener(socket, &block)
        socket.on(:open) { block.call(self) } if block
        socket.on(:close) { @sockets.delete(socket) }
      end

      def setup_listener(socket)
        socket.on(:message) do |message|
          (cmd, _, body) = message.partition(': ')
          @listeners[cmd].each {|l| l.call(body) } if @listeners[cmd]
        end
      end
    end
  end
end
