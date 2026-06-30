class Camper < ApplicationRecord
  has_one :cart, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :balance_adjustments, dependent: :destroy

  validates :name, presence: true
  validates :balance, presence: true, numericality: true

  def cart_or_create
    cart || create_cart
  end
end
