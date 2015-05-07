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

ActiveRecord::Schema.define(version: 20150504114104) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "api_keys", force: true do |t|
    t.integer "user_id"
    t.string  "access_token"
    t.date    "last_access"
  end

  create_table "audits", force: true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         default: 0
    t.string   "comment"
    t.string   "remote_address"
    t.string   "request_uuid"
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], name: "associated_index", using: :btree
  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["created_at"], name: "index_audits_on_created_at", using: :btree
  add_index "audits", ["request_uuid"], name: "index_audits_on_request_uuid", using: :btree
  add_index "audits", ["user_id", "user_type"], name: "user_index", using: :btree

  create_table "billing_invoices", force: true do |t|
    t.integer  "user_id"
    t.decimal  "full_amount",      precision: 8, scale: 2
    t.decimal  "amount",           precision: 8, scale: 2
    t.text     "params"
    t.datetime "paid_at"
    t.date     "issue_date"
    t.date     "due_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.decimal  "credit_deduction", precision: 8, scale: 2
    t.integer  "domain_id"
    t.string   "type_of"
    t.decimal  "provider_price"
  end

  create_table "billing_plans", force: true do |t|
    t.string   "title"
    t.string   "key"
    t.decimal  "monthly_amount", precision: 8, scale: 2
    t.decimal  "annual_amount",  precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "billing_subscriptions", force: true do |t|
    t.string   "type_of"
    t.integer  "user_id"
    t.string   "domain"
    t.date     "subscription_date"
    t.date     "unsubscription_date"
    t.datetime "billed_at"
    t.date     "previous_billing_date"
    t.date     "next_billing_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "billing_transactions", force: true do |t|
    t.integer  "user_id"
    t.integer  "invoice_id"
    t.string   "action"
    t.decimal  "amount",     precision: 8, scale: 2
    t.boolean  "success"
    t.string   "message"
    t.text     "params"
    t.boolean  "refunded"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "com_emails", force: true do |t|
    t.string   "message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delegated_domains", force: true do |t|
    t.integer  "domain_id"
    t.integer  "inviter_id"
    t.integer  "to"
    t.boolean  "accepted",   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cellphone"
  end

  create_table "domains", force: true do |t|
    t.integer  "user_id"
    t.date     "registration_date"
    t.string   "domain"
    t.date     "expiry_date"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_accounts", force: true do |t|
    t.integer  "provider_id"
    t.string   "email"
    t.integer  "user_id"
    t.integer  "domain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_admin",    default: false
    t.string   "name"
    t.boolean  "is_enabled"
  end

  create_table "email_accounts_groups", id: false, force: true do |t|
    t.integer "group_id",         null: false
    t.integer "email_account_id", null: false
  end

  create_table "groups", force: true do |t|
    t.string   "email"
    t.integer  "domain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
  end

  create_table "invites", force: true do |t|
    t.string   "cellphone"
    t.integer  "inviter_id"
    t.integer  "domain_id"
    t.boolean  "accepted",   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "email_id"
  end

  create_table "payments", force: true do |t|
    t.integer  "user_id"
    t.string   "type"
    t.string   "reference"
    t.decimal  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ps_config_zones", force: true do |t|
    t.string  "name"
    t.decimal "orig_price"
    t.decimal "ps_price"
    t.integer "years"
  end

  create_table "ps_configs", force: true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
  end

  create_table "tickets", force: true do |t|
    t.integer  "user_id"
    t.text     "message"
    t.text     "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_to_company_roles", force: true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.integer  "domain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "cellphone"
    t.string   "name"
    t.boolean  "activated",            default: false
    t.string   "confirmation_hash"
    t.string   "device_token"
    t.string   "recovery_cellphone"
    t.string   "recovery_hash"
    t.string   "aasm_state"
    t.string   "temp_device_token"
    t.decimal  "internal_credit"
    t.string   "authentication_token"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "yandex_crons", force: true do |t|
    t.string "domain"
    t.string "email"
  end

end
