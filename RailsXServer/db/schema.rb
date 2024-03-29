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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130525055258) do

  create_table "chats", :force => true do |t|
    t.integer  "screen_id",  :null => false
    t.string   "name"
    t.string   "icon"
    t.text     "message",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "url"
  end

  create_table "oauths", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.string   "secret"
    t.string   "name"
    t.string   "icon"
    t.string   "display_name"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "oauths", ["provider", "uid"], :name => "index_oauths_on_provider_and_uid", :unique => true
  add_index "oauths", ["user_id"], :name => "index_oauths_on_user_id"

  create_table "screens", :force => true do |t|
    t.string   "url",                                 :null => false
    t.integer  "user_id"
    t.datetime "last_cast"
    t.integer  "total_viewer",         :default => 0
    t.integer  "max_viewer",           :default => 0
    t.integer  "total_time",           :default => 0
    t.integer  "state",                :default => 0
    t.integer  "current_time",         :default => 0
    t.integer  "current_total_viewer", :default => 0
    t.integer  "current_max_viewer",   :default => 0
    t.integer  "current_viewer",       :default => 0
    t.string   "title"
    t.string   "color"
    t.text     "vt100"
    t.integer  "pause_count",          :default => 0
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "cast_count",           :default => 0
    t.string   "hash_tag"
  end

  add_index "screens", ["url"], :name => "by_url", :unique => true

  create_table "users", :force => true do |t|
    t.string   "name",                               :null => false
    t.string   "email",                              :null => false
    t.string   "password_digest",                    :null => false
    t.string   "auth_key",                           :null => false
    t.boolean  "email_verified",  :default => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "display_name"
    t.string   "icon"
  end

  add_index "users", ["email"], :name => "by_email", :unique => true
  add_index "users", ["name"], :name => "by_name", :unique => true

end
