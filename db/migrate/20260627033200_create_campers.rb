class CreateCampers < ActiveRecord::Migration[8.1]
  def change
    create_table :campers do |t|
      t.string :name
      t.decimal :balance, precision: 8, scale: 2, default: 150.00, null: false

      t.timestamps
    end
  end
end
