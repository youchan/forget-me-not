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
        order_popup: -> (evt) { props[:order_popup].call(evt, props[:entry]) },
        pomodoro_popup: -> (evt) { props[:pomodoro_popup].call(evt, props[:entry]) },
        onCheck: -> (evt, entry) { entry.done = evt.target.checked?; entry.save }
      }
    ))}
    config.prop_key = :entry
    config.sort_by(:order)
  end

  def initial_state
    { new_todo: '', entries: [], order_popup_visible: false, pomodoro_popup_visible: false, mouse_pos: {x:0,y:0}, target_pos: {x:0,y:0} }
  end

  def component_did_mount
    Entry.fetch(filter: {done: false}, order: 'order') {|entries| set_state(entries: entries) }
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

  def handle_on_pomodoro_select(type)
    set_state(pomodoro_popup_visible: false)

    @current_entry.pomodoro = {one: 1, two: 2, three: 3, five: 5, eight: 8}[type]
    @current_entry.save
  end

  def handle_context_menu_on_select(type)
    set_state(order_popup_visible: false)

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
              order_popup: -> (evt, entry) {
                @current_entry = entry
                set_state(
                  order_popup_visible: true,
                  mouse_pos: { x: evt.offset.x + evt.target.position.x, y: evt.offset.y + evt.target.position.y }
                )
              },
              pomodoro_popup: -> (evt, entry) {
                @current_entry = entry
                set_state(
                  pomodoro_popup_visible: true,
                  target_pos: { x: evt.target.position.x, y: evt.target.position.y }
                )
              }
            )
          )
        )
      ),
      ScheduleView.el,
      br(className: 'clears'),
      ContextMenu.el(
        visible: @state[:order_popup_visible],
        position: @state[:mouse_pos],
        options: {top: "先頭へ", up:"1つ上", down:"1つ下", tail: "末尾に"},
        onSelect: -> (type) { handle_context_menu_on_select(type) }
      ),
      ContextMenu.el(
        visible: @state[:pomodoro_popup_visible],
        position: @state[:target_pos],
        options: {one: "*", two:"**", three:"***", five: "*****"},
        onSelect: -> (type) { handle_on_pomodoro_select(type) }
      )
    )
  end
end

class DescriptionView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def component_did_mount
    @props[:entry].on(:change, :done, :pomodoro) do |value|
      force_update
    end
  end

  def render
    div({className:"description"},
      input({type: 'checkbox', checked: @props[:entry].done, onChange: -> (evt) { @props[:onCheck].call(evt, @props[:entry]) }}),
      span({className: 'description' + (@props[:entry].done ? ' done' : ''), onClick: -> (evt) { @props[:order_popup].call(evt) } }, @props[:entry].description),
      span({className: 'pomodoro', onClick: -> (evt) { @props[:pomodoro_popup].call(evt) } },
        @props[:entry].pomodoro.times.map{ img(className: 'pomodoro', src: 'images/pomodoro.png') }
      )
    )
  end
end
