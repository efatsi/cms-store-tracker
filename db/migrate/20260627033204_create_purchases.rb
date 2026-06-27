class CreatePurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :purchases do |t|
      t.references :camper, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :price_at_purchase, precision: 8, scale: 2, null: false

      t.timestamps
    end
  end
end
