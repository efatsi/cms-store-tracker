class Cart < ApplicationRecord
  belongs_to :camper, optional: true
  belongs_to :staff_member, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def total
    cart_items.sum { |item| item.product.price * item.quantity }
  end
end
