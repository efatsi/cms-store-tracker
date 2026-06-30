class ApiController < ApplicationController
  def product_purchases
    product = Product.find(params[:id])
    records = product.purchases.includes(:camper).order(created_at: :desc).map do |p|
      {
        camper_id: p.camper_id,
        camper_name: p.camper.name,
        quantity: p.quantity,
        price_at_purchase: p.price_at_purchase.to_f,
        created_at: p.created_at.strftime("%b %-d, %Y at %-I:%M %p")
      }
    end
    render json: { product_name: product.name, purchases: records }
  end
end
