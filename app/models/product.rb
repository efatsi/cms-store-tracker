class Product < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :purchases, dependent: :destroy

  validates :name, :section, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :available, -> { where("quantity > 0") }
end
