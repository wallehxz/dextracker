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

ActiveRecord::Schema.define(version: 20220124075451) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.integer  "exchange_id"
    t.string   "asset"
    t.string   "quote"
    t.float    "balance"
    t.float    "freezen"
    t.float    "cost"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "announces", force: :cascade do |t|
    t.string   "title"
    t.string   "link"
    t.string   "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exchanges", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "app_key"
    t.string   "app_secret"
    t.string   "type"
    t.string   "remark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "launchpads", force: :cascade do |t|
    t.integer  "exchange_id"
    t.string   "base"
    t.string   "quote"
    t.string   "state"
    t.float    "funds"
    t.datetime "launch_at"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.float    "limit_bid",   default: 0.0
  end

  create_table "markets", force: :cascade do |t|
    t.integer  "exchange_id"
    t.string   "quote"
    t.string   "base"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "precision"
    t.float    "pounds"
  end

  create_table "orders", force: :cascade do |t|
    t.integer  "exchange_id"
    t.integer  "market_id"
    t.string   "type"
    t.float    "amount"
    t.float    "price"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "state"
    t.string   "msg"
  end

  create_table "periods", force: :cascade do |t|
    t.integer  "market_id"
    t.integer  "period"
    t.string   "state"
    t.float    "amount"
    t.float    "bid_qty"
    t.float    "ask_qty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "snapshots", force: :cascade do |t|
    t.integer  "exchange_id"
    t.string   "period"
    t.string   "time_stamp"
    t.float    "estimate"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "trades", force: :cascade do |t|
    t.integer  "market_id"
    t.integer  "period"
    t.string   "number"
    t.string   "cate"
    t.string   "timestamp"
    t.float    "amount"
    t.float    "price"
    t.float    "total"
    t.datetime "completed_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "role"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
