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

ActiveRecord::Schema[8.1].define(version: 2026_03_07_181355) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "call_participants", force: :cascade do |t|
    t.bigint "call_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "joined_at", null: false
    t.datetime "left_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["call_session_id", "user_id"], name: "index_call_participants_on_call_session_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_call_participants_on_user_id"
  end

  create_table "call_sessions", force: :cascade do |t|
    t.integer "call_type", default: 0, null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.bigint "initiator_id", null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "status"], name: "index_call_sessions_on_conversation_id_and_status"
    t.index ["initiator_id"], name: "index_call_sessions_on_initiator_id"
  end

  create_table "conversation_members", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_members_on_conversation_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_conversation_members_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.integer "conversation_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["conversation_type"], name: "index_conversations_on_conversation_type"
    t.index ["created_by_id"], name: "index_conversations_on_created_by_id"
    t.index ["name"], name: "index_conversations_on_name"
  end

  create_table "messages", primary_key: ["id", "created_at"], options: "PARTITION BY RANGE (created_at)", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "deleted_at"
    t.timestamptz "edited_at"
    t.bigserial "id", null: false
    t.integer "message_type", default: 0, null: false
    t.timestamptz "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["deleted_at"], name: "index_messages_on_deleted_at", where: "(deleted_at IS NOT NULL)"
  end

  create_table "messages_2026_03", primary_key: ["id", "created_at"], options: "INHERITS (messages)", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.timestamptz "created_at", null: false
    t.timestamptz "deleted_at"
    t.timestamptz "edited_at"
    t.bigint "id", default: -> { "nextval('messages_id_seq'::regclass)" }, null: false
    t.integer "message_type", default: 0, null: false
    t.timestamptz "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id", "created_at"], name: "messages_2026_03_conversation_id_created_at_idx"
    t.index ["deleted_at"], name: "messages_2026_03_deleted_at_idx", where: "(deleted_at IS NOT NULL)"
  end

  create_table "reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.datetime "message_created_at", null: false
    t.bigint "message_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["message_id", "user_id", "emoji"], name: "index_reactions_on_message_id_and_user_id_and_emoji", unique: true
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_seen_at"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_seen_at"], name: "index_users_on_last_seen_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "call_participants", "call_sessions"
  add_foreign_key "call_participants", "users"
  add_foreign_key "call_sessions", "conversations"
  add_foreign_key "call_sessions", "users", column: "initiator_id"
  add_foreign_key "conversation_members", "conversations"
  add_foreign_key "conversation_members", "users"
  add_foreign_key "conversations", "users", column: "created_by_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "messages_2026_03", "conversations"
  add_foreign_key "messages_2026_03", "users"
  add_foreign_key "reactions", "users"
end
