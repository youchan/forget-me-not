# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_12_010608) do
  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default", default: false, null: false
    t.index ["user_id", "name"], name: "index_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
    t.index ["user_id"], name: "index_categories_on_user_id_when_default", unique: true, where: "is_default = 1"
  end

  create_table "passkeys", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "external_id", null: false
    t.string "public_key", null: false
    t.string "nickname"
    t.integer "sign_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_passkeys_on_external_id", unique: true
    t.index ["user_id"], name: "index_passkeys_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "task_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["task_id", "tag_id"], name: "index_taggings_on_task_id_and_tag_id", unique: true
    t.index ["task_id"], name: "index_taggings_on_task_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_tags_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "parent_id"
    t.integer "position", default: 0, null: false
    t.integer "estimate_pomodoros"
    t.date "starts_on"
    t.date "due_on"
    t.datetime "completed_at"
    t.integer "category_id", null: false
    t.index ["category_id"], name: "index_tasks_on_category_id"
    t.index ["parent_id"], name: "index_tasks_on_parent_id"
    t.index ["user_id", "parent_id", "position"], name: "index_tasks_on_user_id_and_parent_id_and_position"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "webauthn_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["webauthn_id"], name: "index_users_on_webauthn_id", unique: true
  end

  add_foreign_key "categories", "users"
  add_foreign_key "passkeys", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "taggings", "tasks"
  add_foreign_key "tags", "users"
  add_foreign_key "tasks", "categories"
  add_foreign_key "tasks", "tasks", column: "parent_id"
  add_foreign_key "tasks", "users"
end
