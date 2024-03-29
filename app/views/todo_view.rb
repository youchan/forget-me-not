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
        onCheck: -> (evt, entry) { entry.done = evt.target[:checked]; entry.save }
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
      max_order ||= 0
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

  def context_menu
    if @state[:order_popup_visible]
      ContextMenu.el(
        position: @state[:mouse_pos],
        options: {top: "先頭へ", up:"1つ上", down:"1つ下", tail: "末尾に"},
        onSelect: -> (type) { handle_context_menu_on_select(type) }
      )
    elsif @state[:pomodoro_popup_visible]
      ContextMenu.el(
        position: @state[:target_pos],
        options: {one: 1, two: 2, three: 3, five: 5, eight: 8},
        cellComponent: PomodoroCell,
        onSelect: -> (type) { handle_on_pomodoro_select(type) }
      )
    else
      nil
    end
  end

  def render
    div(nil,
      div({class: 'todo-view'},
        div({class: 'todo-input'},
          label({'for': 'new-todo'}, 'Todo:'),
          input(
            id: 'new-todo',
            class: 'new-todo',
            type: 'text',
            onKeyDown: -> (event) { handle_input_on_keydown(event) },
            ref: 'new-todo')),
        div({class: 'entries'},
          div({class:"acc-content"},
            TodoList.el(
              collection: @state[:entries],
              order_popup: -> (evt, entry) {
                @current_entry = entry
                set_state(
                  order_popup_visible: true,
                  mouse_pos: { x: evt.offset.x + evt.target.client_rect.left, y: evt.offset.y + evt.target.client_rect.top }
                )
              },
              pomodoro_popup: -> (evt, entry) {
                @current_entry = entry
                set_state(
                  pomodoro_popup_visible: true,
                  target_pos: { x: evt.offset.x + evt.target.client_rect.left, y: evt.offset.y + evt.target.client_rect.top }
                )
              }
            )
          )
        )
      ),
      ScheduleView.el,
      br(class: 'clears'),
      context_menu
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

  def description
    @state[:edit] ?
      input({class: 'edit-description', type: 'text', value: @props[:entry].description}) :
      span({class: 'label-description' + (@props[:entry].done ? ' done' : ''), onClick: -> { set_state(edit: true) } }, @props[:entry].description)
  end
  
  def pomodoro_list
    pomodoro = @props[:entry].pomodoro
    pomodoro < 5 ?
      pomodoro.times.map{ img(class: 'pomodoro', src: 'images/pomodoro.png') } :
      [img(class: 'pomodoro', src: 'images/pomodoro.png'), span(nil, " x #{pomodoro}") ]
  end

  def render
    div({class:"description"},
      p({},
        input({type: 'checkbox', checked: @props[:entry].done, onChange: -> (evt) { @props[:onCheck].call(evt, @props[:entry]) }}),
        description,
        span({class: 'pomodoro', onClick: -> (evt) { @props[:pomodoro_popup].call(evt) } }, pomodoro_list)
      ),
      p({},
        span({class: 'reorder-todo', onClick: -> (evt) {  @props[:order_popup].call(evt) } },
          img(class: 'reorder', src: 'images/reorder.png')
        )
      )
    )
  end
end
