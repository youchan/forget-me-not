require 'hyalite'
require_relative 'todo_view'

class App
  include Hyalite::Component::ShortHand

  def self.render
    Hyalite.render(TodoView.el, $document["#todo-tab"])
  end
end

$document.ready do
  App.render
end
