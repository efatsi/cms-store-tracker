class CreateBalanceAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :balance_adjustments do |t|
      t.references :camper, null: false, foreign_key: true
      t.decimal :amount, precision: 8, scale: 2
      t.text :notes

      t.timestamps
    end
  end
end
