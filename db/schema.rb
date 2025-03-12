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

ActiveRecord::Schema[8.0].define(version: 2025_03_12_092224) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_gateway_api_keys", force: :cascade do |t|
    t.bigint "organisations_id", null: false
    t.string "api_key_id", null: false
    t.string "api_gateway_id", null: false
    t.boolean "enabled"
    t.string "secret", null: false
    t.string "usage_plan_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisations_id"], name: "index_api_gateway_api_keys_on_organisations_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "organisation_id", null: false
    t.string "application_reference"
    t.string "description"
    t.string "eori_number"
    t.string "organisation_name"
    t.integer "status"
    t.string "uk_acs_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.bigint "organisations_id", null: false
    t.string "email_address"
    t.string "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisations_id"], name: "index_users_on_organisations_id"
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

  add_foreign_key "api_gateway_api_keys", "organisations", column: "organisations_id"
  add_foreign_key "users", "organisations", column: "organisations_id"
end
