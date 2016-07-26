require 'sinatra/base'
require 'line/bot'

class Notification
  def initialize
    @client = Line::Bot::Client.new {|config|
      config.channel_id = ENV["LINE_CHANNEL_ID"] || "1468491501"
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"] || "ae41f4f771c96e771f09b043991d56f7"
      config.channel_mid = ENV["LINE_CHANNEL_MID"] || "u8924d91ce557130dd1e720de521db298"
    }
  end

  def routes
    Sinatra.new do
      post '/callback' do
        signature = request.env['HTTP_X_LINE_CHANNELSIGNATURE']
        unless @client.validate_signature(request.body.read, signature)
          error 400 do 'Bad Request' end
        end

        receive_request = Line::Bot::Receive::Request.new(request.env)

        receive_request.data.each { |message|
          case message.content
          when Line::Bot::Message::Text
            @client.send_text(
              to_mid: message.from_mid,
              text: message.content[:text],
            )
          end
        }

        "OK"
      end
    end
  end

  def send(text)
    @client.send_text(
      to_mid:  "u8924d91ce557130dd1e720de521db298",
      text: text
    )
  end
end
