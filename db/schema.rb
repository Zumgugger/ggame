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

ActiveRecord::Schema[7.2].define(version: 2026_01_17_110002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.datetime "time"
    t.integer "group_id"
    t.boolean "noticed"
    t.integer "points_set"
    t.integer "target_id"
    t.string "description"
    t.integer "target_group_id"
    t.integer "group_points"
    t.integer "target_points"
    t.integer "target_group_points"
    t.integer "option_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_settings", force: :cascade do |t|
    t.decimal "point_multiplier", precision: 3, scale: 2, default: "1.0"
    t.datetime "game_start_time"
    t.datetime "game_end_time"
    t.boolean "game_active", default: false
    t.json "default_values"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_time_windows", force: :cascade do |t|
    t.bigint "game_setting_id", null: false
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "name"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_setting_id", "position"], name: "index_game_time_windows_on_game_setting_id_and_position"
    t.index ["game_setting_id"], name: "index_game_time_windows_on_game_setting_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.integer "points", default: 0
    t.boolean "false_information"
    t.integer "kopfgeld"
    t.integer "sort_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "join_token", null: false
    t.boolean "name_editable", default: true
    t.index ["join_token"], name: "index_groups_on_join_token", unique: true
  end

  create_table "option_settings", force: :cascade do |t|
    t.bigint "option_id", null: false
    t.boolean "requires_photo", default: false
    t.boolean "requires_target", default: false
    t.boolean "auto_verify", default: true
    t.integer "points", default: 0
    t.integer "cost", default: 0
    t.integer "cooldown_seconds", default: 0
    t.text "rule_text"
    t.text "rule_text_default"
    t.boolean "available_to_players", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["option_id"], name: "index_option_settings_on_option_id"
  end

  create_table "options", force: :cascade do |t|
    t.string "name"
    t.integer "count"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "player_sessions", force: :cascade do |t|
    t.string "device_fingerprint", null: false
    t.string "session_token", null: false
    t.string "player_name"
    t.bigint "group_id"
    t.datetime "joined_at"
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_fingerprint"], name: "index_player_sessions_on_device_fingerprint", unique: true
    t.index ["group_id"], name: "index_player_sessions_on_group_id"
    t.index ["session_token"], name: "index_player_sessions_on_session_token", unique: true
  end

  create_table "targets", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "points", default: 100
    t.integer "mines", default: 0
    t.integer "count", default: 0
    t.datetime "last_action"
    t.string "village"
    t.integer "sort_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "phone_number"
    t.bigint "group_id"
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "game_time_windows", "game_settings"
  add_foreign_key "option_settings", "options"
  add_foreign_key "player_sessions", "groups"
  add_foreign_key "users", "groups"
end
