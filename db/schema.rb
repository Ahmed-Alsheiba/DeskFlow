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

ActiveRecord::Schema[8.0].define(version: 2025_11_27_084512) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "comments", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.text "content", null: false
    t.string "author_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_comments_on_ticket_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "category"
    t.string "status", default: "open", null: false
    t.string "priority", default: "medium", null: false
    t.string "location"
    t.string "submitter_name"
    t.string "assigned_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["priority"], name: "index_tickets_on_priority"
    t.index ["status"], name: "index_tickets_on_status"
  end

  add_foreign_key "comments", "tickets"
end
