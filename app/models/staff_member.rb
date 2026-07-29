class StaffMember < ApplicationRecord
  has_one :cart, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :staff_balance_adjustments, dependent: :destroy

  validates :name, presence: true

  def cart_or_create
    cart || create_cart
  end

  def purchased_amount
    purchases.sum(&:subtotal) + staff_balance_adjustments.sum(:amount)
  end
end
