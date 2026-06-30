class BalanceAdjustment < ApplicationRecord
  belongs_to :camper
  validates :amount, presence: true, numericality: { other_than: 0 }
end
