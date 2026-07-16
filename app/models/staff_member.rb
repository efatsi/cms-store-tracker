class StaffMember < ApplicationRecord
  has_one :cart, dependent: :destroy
  has_many :purchases, dependent: :destroy

  validates :name, presence: true

  def cart_or_create
    cart || create_cart
  end

  def purchased_amount
    purchases.sum(&:subtotal)
  end
end
