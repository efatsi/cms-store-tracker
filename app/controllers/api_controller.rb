class ApiController < ApplicationController
  def data
    campers = Camper.order(:name).map do |c|
      { id: c.id, name: c.name, balance: c.balance.to_f }
    end

    products = Product.where("quantity > 0").order(:section, :name).map do |p|
      { id: p.id, name: p.name, price: p.price.to_f, quantity: p.quantity, section: p.section }
    end

    carts = {}
    Cart.includes(cart_items: :product).each do |cart|
      carts[cart.camper_id.to_s] = cart.cart_items.map do |item|
        {
          id: item.id,
          product_id: item.product_id,
          product_name: item.product.name,
          product_price: item.product.price.to_f,
          quantity: item.quantity
        }
      end
    end

    purchases = {}
    Purchase.includes(:product).order(created_at: :desc).each do |p|
      key = p.camper_id.to_s
      purchases[key] ||= []
      purchases[key] << {
        id: p.id,
        product_name: p.product.name,
        quantity: p.quantity,
        price_at_purchase: p.price_at_purchase.to_f,
        created_at: p.created_at.strftime("%b %-d at %-I:%M %p")
      }
    end

    render json: { campers:, products:, carts:, purchases: }
  end
end
