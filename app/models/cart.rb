class Cart < ApplicationRecord
  belongs_to :camper
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def total
    cart_items.sum { |item| item.product.price * item.quantity }
  end
end
