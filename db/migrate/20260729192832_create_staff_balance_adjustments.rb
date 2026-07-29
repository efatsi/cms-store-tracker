class CreateStaffBalanceAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_balance_adjustments do |t|
      t.references :staff_member, null: false, foreign_key: true
      t.decimal :amount, precision: 8, scale: 2
      t.text :notes

      t.timestamps
    end
  end
end
