require_relative 'schedule_view'
require_relative 'context_menu'
require_relative '../models/entry'
require_relative '../base/hyalite/sortable'
require_relative '../base/hyalite/proxy_component'

class TodoView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  TodoList = Hyalite::Sortable.create do |config|
    config.wrap = Hyalite.fn {|props| ol({className:"selectable"}, props[:children]) }
    config.component = Hyalite.fn {|props| li(nil, DescriptionView.el(
      {
        entry: props[:entry],
        popup: -> (evt) { props[:popup].call(evt, props[:entry]) },
        onCheck: -> (evt, entry) { entry.done = evt.target.checked?; entry.save }
      }
    ))}
    config.prop_key = :entry
    config.sort_by(:order)
  end

  def initial_state
    Entry.fetch(filter: {done: false}, order: 'order') {|entries| set_state(entries: entries) }
    { new_todo: '', entries: [], popup_visible: false, mouse_pos: {x:0,y:0} }
  end

  def add_entry
    max_order = Entry.max(:order)
    entry = Entry.new(description: @state[:new_todo], pomodoro: 1, order: max_order + 1)
    entry.save do
      @state[:entries] << entry
      @state[:new_todo] = ''
      set_state(@state)
    end
  end

  def handle_change(event)
    set_state(new_todo: event.target.value)
  end

  def handle_input_on_keydown(event)
    if event.code == 13
      add_entry
    end
  end

  def handle_context_menu_on_select(type)
    set_state(popup_visible: false)

    index = @state[:entries].index(@current_entry)
    case type
    when :top
      @state[:entries].delete(@current_entry)
      @state[:entries].insert(0, @current_entry)
    when :tail
      @state[:entries].delete(@current_entry)
      @state[:entries] << @current_entry
    when :up
      @state[:entries].delete(@current_entry)
      @state[:entries].insert(index - 1, @current_entry)
    when :down
      @state[:entries].delete(@current_entry)
      @state[:entries].insert(index + 1, @current_entry)
    end

    @state[:entries].each_with_index {|entry, i| entry.order = i + 1 }

    Entry.save(@state[:entries]) do |entries|
      set_state(entries: entries)
    end
  end

  def render
    div(nil,
      div({className: 'todo-view'},
        label({'for': 'new-todo'}, 'Todo:'),
        input(
          id: 'new-todo',
          className: 'new-todo',
          type: 'text',
          onKeyDown: -> (event) { handle_input_on_keydown(event) },
          onChange: -> (event) { handle_change(event) },
          value: @state[:new_todo]),
        div({className: 'entries'},
          div({className:"acc-content"},
            TodoList.el(
              collection: @state[:entries],
              popup: -> (evt, entry) {
                @current_entry = entry
                set_state(
                  popup_visible: true,
                  mouse_pos: { x: evt.offset.x + evt.target.position.x, y: evt.offset.y + evt.target.position.y }
                )
              }
            )
          )
        )
      ),
      ScheduleView.el,
      br(className: 'clears'),
      ContextMenu.el(
        visible: @state[:popup_visible],
        position: @state[:mouse_pos],
        options: {top: "先頭へ", up:"1つ上", down:"1つ下", tail: "末尾に"},
        onSelect: -> (type) { handle_context_menu_on_select(type) }
      )
    )
  end
end

class DescriptionView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def initial_state
    { done: @props[:entry].done }
  end

  def component_did_mount
    @props[:entry].on(:change, :done) do |value|
      set_state(done: value)
    end
  end

  def render
    div({className:"description"},
      input({type: 'checkbox', checked: @state[:done], onChange: -> (evt) { @props[:onCheck].call(evt, @props[:entry]) }}),
      span({className: 'description' + (@state[:done] ? ' done' : ''), onClick: -> (evt) { @props[:popup].call(evt) } }, @props[:entry].description),
      span({className: 'pomodoro'},
        @props[:entry].pomodoro.times.map{ img(className: 'pomodoro', src: 'images/pomodoro.png') }
      )
    )
  end
end
