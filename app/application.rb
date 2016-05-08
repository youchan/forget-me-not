require 'hyalite'
require_relative 'base/client/store'
require_relative 'models/entry'
require_relative 'models/time_box'
require_relative 'views/todo_view'

class App
  include Hyalite::Component::ShortHand

  def self.render
    Hyalite.render(TodoView.el, $document["#todo-tab"])
  end
end

$document.ready do
  App.render
end
