require 'hyalite'
require 'menilite'
require_relative 'models/entry'
require_relative 'models/time_box'
require_relative 'views/todo_view'
require_relative 'push_notification'

class App
  include Hyalite::Component::ShortHand

  def self.render
    Hyalite.render(TodoView.el, $document["#todo-tab"])
  end
end

$document.ready do
  channel = ForgetMeNot::PushNotification.channel(:forget_me_not)
  channel.connect  { puts "channel open!!" }

  App.render
end
