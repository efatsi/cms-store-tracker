class StaffBalanceAdjustment < ApplicationRecord
  belongs_to :staff_member
  validates :amount, presence: true, numericality: { other_than: 0 }
end
