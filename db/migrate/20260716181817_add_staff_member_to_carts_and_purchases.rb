class AddStaffMemberToCartsAndPurchases < ActiveRecord::Migration[8.1]
  def change
    change_column_null :carts, :camper_id, true
    add_reference :carts, :staff_member, null: true, foreign_key: true

    change_column_null :purchases, :camper_id, true
    add_reference :purchases, :staff_member, null: true, foreign_key: true
  end
end
