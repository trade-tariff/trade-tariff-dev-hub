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

ActiveRecord::Schema[8.0].define(version: 2025_10_13_084519) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "invitation_status", ["pending", "accepted", "declined", "expired", "revoked"]

  create_table "api_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organisation_id", null: false
    t.string "api_key_id", null: false
    t.string "api_gateway_id", null: false
    t.boolean "enabled"
    t.string "secret", null: false
    t.string "usage_plan_id", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_id", "organisation_id"], name: "index_api_keys_on_api_key_id_and_organisation_id", unique: true
    t.index ["organisation_id"], name: "index_api_keys_on_organisation_id"
  end

  create_table "invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "invitee_email", null: false
    t.uuid "user_id", null: false
    t.uuid "organisation_id", null: false
    t.enum "status", default: "pending", null: false, enum_type: "invitation_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invitee_email"], name: "index_invitations_on_invitee_email", unique: true
    t.index ["organisation_id"], name: "index_invitations_on_organisation_id"
    t.index ["user_id"], name: "index_invitations_on_user_id"
  end

  create_table "organisations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "organisation_id"
    t.string "application_reference"
    t.string "description"
    t.string "eori_number"
    t.string "organisation_name"
    t.integer "status"
    t.string "uk_acs_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organisations_roles", id: false, force: :cascade do |t|
    t.uuid "organisation_id", null: false
    t.uuid "role_id", null: false
    t.index ["organisation_id", "role_id"], name: "index_organisations_roles_on_organisation_id_and_role_id", unique: true
    t.index ["organisation_id"], name: "index_organisations_roles_on_organisation_id"
    t.index ["role_id"], name: "index_organisations_roles_on_role_id"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "token", null: false
    t.uuid "user_id", null: false
    t.datetime "expires_at"
    t.jsonb "raw_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "id_token", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organisation_id", null: false
    t.string "email_address"
    t.string "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "api_keys", "organisations"
  add_foreign_key "invitations", "organisations"
  add_foreign_key "invitations", "users"
  add_foreign_key "organisations_roles", "organisations"
  add_foreign_key "organisations_roles", "roles"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "organisations"
end
