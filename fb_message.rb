require 'facebook/messenger'


Facebook::Messenger.configure do |config|
  config.client_token = '32233507bcdec37ea851e7ec0be78e4a'
  config.app_secret = 'f9d724c311720b0e26e9829b9f9ab133'
end

Facebook::Messenger::Bot.deliver(
  recipient: {
    id: '45123'
  },
  message: {
    text: 'Human?'
  }
)
