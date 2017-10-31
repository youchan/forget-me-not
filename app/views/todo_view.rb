require_relative 'schedule_view'
require_relative 'context_menu'
require_relative '../models/entry'
require_relative '../base/hyalite/sortable'

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
    { entries: [], order_popup_visible: false, pomodoro_popup_visible: false, mouse_pos: {x:0,y:0}, target_pos: {x:0,y:0} }
  end

  def component_did_mount
    Entry.fetch!(filter: {done: false}, order: 'order') {|entries| set_state(entries: entries) }
  end

  def add_entry
    Entry.max!(:order) do |max_order|
      entry = Entry.new(description: @refs['new-todo'].value, pomodoro: 1, order: max_order + 1)
      entry.save do
        @state[:entries] << entry
        set_state(@state)
        @refs['new-todo'].value = ''
      end
    end
  end

  def handle_input_on_keydown(event)
    if event.code == :Enter
      add_entry
    end
  end

  def handle_on_pomodoro_select(type)
    set_state(pomodoro_popup_visible: false)
    return unless type

    @current_entry.pomodoro = {one: 1, two: 2, three: 3, five: 5, eight: 8}[type]
    @current_entry.save
  end

  def handle_context_menu_on_select(type)
    set_state(order_popup_visible: false)
    return unless type

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
          ref: 'new-todo'),
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
        options: {one: 1, two: 2, three: 3, five: 5, eight: 8},
        cellComponent: PomodoroCell,
        onSelect: -> (type) { handle_on_pomodoro_select(type) }
      )
    )
  end
end

class PomodoroCell
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def render
    length = @props[:value]
    div({},
      span({className: 'pomodoro'},
        length < 5 ?
          length.times.map{ img(className: 'pomodoro', src: 'images/pomodoro.png') } :
          [ img(className: 'pomodoro', src: 'images/pomodoro.png'), span(nil, " x #{length}") ]
      )
    )
  end
end

class DescriptionView
  include Hyalite::Component
  include Hyalite::Component::ShortHand

  def initial_state
    { edit: false }
  end

  def component_did_mount
    @props[:entry].on(:change, :done, :pomodoro) do |value|
      force_update
    end
  end

  def render
    description = @state[:edit] ?
      input({className: 'edit-description', type: 'text', value: @props[:entry].description}) :
      span({className: 'label-description' + (@props[:entry].done ? ' done' : ''), onClick: -> { set_state(edit: true) } }, @props[:entry].description)

    pomodoro = @props[:entry].pomodoro

    div({className:"description"},
      input({type: 'checkbox', checked: @props[:entry].done, onChange: -> (evt) { @props[:onCheck].call(evt, @props[:entry]) }}),
      description,
      span({className: 'reorder-todo', onClick: -> (evt) {  @props[:order_popup].call(evt) } }, img(className: 'reorder', src: 'images/reorder.png')),
      span({className: 'pomodoro', onClick: -> (evt) { @props[:pomodoro_popup].call(evt) } },
        pomodoro < 5 ?
          pomodoro.times.map{ img(className: 'pomodoro', src: 'images/pomodoro.png') } :
          [img(className: 'pomodoro', src: 'images/pomodoro.png'), span(nil, " x #{pomodoro}") ]
      )
    )
  end
end
