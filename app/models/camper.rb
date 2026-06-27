class Camper < ApplicationRecord
  has_one :cart, dependent: :destroy
  has_many :purchases, dependent: :destroy

  validates :name, presence: true
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def cart_or_create
    cart || create_cart
  end
end
