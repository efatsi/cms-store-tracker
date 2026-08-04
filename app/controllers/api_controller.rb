class ApiController < ApplicationController
  def product_purchases
    product = Product.find(params[:id])
    records = product.purchases.includes(:camper, :staff_member).order(created_at: :desc).map do |p|
      buyer = p.camper || p.staff_member
      {
        camper_id: p.camper_id || "staff_#{p.staff_member_id}",
        camper_name: buyer&.name || "Unknown",
        is_staff: p.staff_member_id.present?,
        quantity: p.quantity,
        price_at_purchase: p.price_at_purchase.to_f,
        created_at: p.created_at.strftime("%b %-d, %Y at %-I:%M %p")
      }
    end
    render json: { product_name: product.name, purchases: records }
  end
end
