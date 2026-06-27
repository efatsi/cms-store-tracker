class Purchase < ApplicationRecord
  belongs_to :camper
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_at_purchase, presence: true, numericality: { greater_than: 0 }

  def subtotal
    price_at_purchase * quantity
  end
end
