# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2016_10_07_120531) do

  create_table "entries", force: :cascade do |t|
    t.string "guid"
    t.string "description"
    t.integer "pomodoro"
    t.integer "order"
    t.boolean "done", default: false, null: false
  end

  create_table "time_boxes", force: :cascade do |t|
    t.string "guid"
    t.string "entry_guid"
    t.integer "pomodoro"
    t.integer "start_at"
    t.date "date"
    t.integer "status", default: 0, null: false
  end

end
