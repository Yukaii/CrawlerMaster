# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160803081532) do

  create_table "admin_users", force: :cascade do |t|
    t.string   "username",               default: ""
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  add_index "admin_users", ["username"], name: "index_admin_users_on_username", unique: true

  create_table "course_task_relations", force: :cascade do |t|
    t.integer  "version_id"
    t.integer  "task_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "course_task_relations", ["task_id", "version_id"], name: "index_course_task_relations_on_task_id_and_version_id", unique: true
  add_index "course_task_relations", ["task_id"], name: "index_course_task_relations_on_task_id"
  add_index "course_task_relations", ["version_id"], name: "index_course_task_relations_on_version_id"

  create_table "courses", force: :cascade do |t|
    t.string   "organization_code", null: false
    t.string   "department_code"
    t.string   "lecturer"
    t.integer  "year",              null: false
    t.integer  "term",              null: false
    t.string   "name"
    t.string   "code"
    t.string   "general_code"
    t.string   "ucode"
    t.boolean  "required"
    t.integer  "credits"
    t.string   "url"
    t.string   "name_en"
    t.boolean  "full_semester"
    t.integer  "day_1"
    t.integer  "day_2"
    t.integer  "day_3"
    t.integer  "day_4"
    t.integer  "day_5"
    t.integer  "day_6"
    t.integer  "day_7"
    t.integer  "day_8"
    t.integer  "day_9"
    t.integer  "period_1"
    t.integer  "period_2"
    t.integer  "period_3"
    t.integer  "period_4"
    t.integer  "period_5"
    t.integer  "period_6"
    t.integer  "period_7"
    t.integer  "period_8"
    t.integer  "period_9"
    t.string   "location_1"
    t.string   "location_2"
    t.string   "location_3"
    t.string   "location_4"
    t.string   "location_5"
    t.string   "location_6"
    t.string   "location_7"
    t.string   "location_8"
    t.string   "location_9"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "courses", ["code"], name: "index_courses_on_code"
  add_index "courses", ["general_code"], name: "index_courses_on_general_code"
  add_index "courses", ["organization_code"], name: "index_courses_on_organization_code"
  add_index "courses", ["required"], name: "index_courses_on_required"
  add_index "courses", ["term"], name: "index_courses_on_term"
  add_index "courses", ["ucode"], name: "index_courses_on_ucode"
  add_index "courses", ["year"], name: "index_courses_on_year"

  create_table "crawl_tasks", force: :cascade do |t|
    t.integer  "type",        default: 0, null: false
    t.datetime "finished_at"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "crawl_tasks", ["type"], name: "index_crawl_tasks_on_type"

  create_table "crawlers", force: :cascade do |t|
    t.string   "name"
    t.string   "short_name"
    t.string   "class_name"
    t.string   "organization_code"
    t.string   "setting"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "data_management_api_endpoint"
    t.string   "data_management_api_key"
    t.string   "data_name"
    t.boolean  "save_to_db",                   default: true
    t.boolean  "sync",                         default: false
    t.string   "category"
    t.string   "description"
    t.integer  "year"
    t.integer  "term"
    t.datetime "last_sync_at"
    t.integer  "courses_count"
    t.datetime "last_run_at"
  end

  create_table "rufus_jobs", force: :cascade do |t|
    t.string   "jid"
    t.integer  "crawler_id"
    t.string   "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "original"
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",                     null: false
    t.integer  "item_id",                       null: false
    t.string   "event",                         null: false
    t.string   "whodunnit"
    t.text     "object",     limit: 1073741823
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"

end
