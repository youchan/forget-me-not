require 'line/bot'

client = Line::Bot::Client.new {|config|
  config.channel_id = ENV["LINE_CHANNEL_ID"] || "1468491501"
  config.channel_secret = ENV["LINE_CHANNEL_SECRET"] || "ae41f4f771c96e771f09b043991d56f7"
  config.channel_mid = ENV["LINE_CHANNEL_MID"] || "u8924d91ce557130dd1e720de521db298"
}


client.send_text(
  to_mid:  "u381f4a5c05fcc3541500047ec31bb0fb",
  text: "test"
)
