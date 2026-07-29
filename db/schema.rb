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

ActiveRecord::Schema[8.1].define(version: 2026_07_29_192832) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "balance_adjustments", force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 2
    t.bigint "camper_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["camper_id"], name: "index_balance_adjustments_on_camper_id"
  end

  create_table "campers", force: :cascade do |t|
    t.decimal "balance", precision: 8, scale: 2, default: "150.0", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "camper_id"
    t.datetime "created_at", null: false
    t.bigint "staff_member_id"
    t.datetime "updated_at", null: false
    t.index ["camper_id"], name: "index_carts_on_camper_id"
    t.index ["staff_member_id"], name: "index_carts_on_staff_member_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.decimal "price", precision: 8, scale: 2, null: false
    t.integer "quantity"
    t.string "section"
    t.datetime "updated_at", null: false
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "camper_id"
    t.datetime "created_at", null: false
    t.decimal "price_at_purchase", precision: 8, scale: 2, null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.bigint "staff_member_id"
    t.datetime "updated_at", null: false
    t.index ["camper_id"], name: "index_purchases_on_camper_id"
    t.index ["product_id"], name: "index_purchases_on_product_id"
    t.index ["staff_member_id"], name: "index_purchases_on_staff_member_id"
  end

  create_table "staff_balance_adjustments", force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "staff_member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["staff_member_id"], name: "index_staff_balance_adjustments_on_staff_member_id"
  end

  create_table "staff_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "balance_adjustments", "campers"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "campers"
  add_foreign_key "carts", "staff_members"
  add_foreign_key "purchases", "campers"
  add_foreign_key "purchases", "products"
  add_foreign_key "purchases", "staff_members"
  add_foreign_key "staff_balance_adjustments", "staff_members"
end
