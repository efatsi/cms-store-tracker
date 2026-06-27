class PurchasesController < ApplicationController
  before_action :set_camper

  def create
    @cart = @camper.cart_or_create
    cart_items = @cart.cart_items.includes(:product)

    if cart_items.empty?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Your cart is empty." }
        format.json { render json: { error: "Cart is empty" }, status: :unprocessable_entity }
      end
      return
    end

    total = cart_items.sum { |item| item.product.price * item.quantity }

    ActiveRecord::Base.transaction do
      cart_items.each do |item|
        product = item.product
        raise ActiveRecord::Rollback, "#{product.name} is out of stock." if product.quantity < item.quantity

        @camper.purchases.create!(
          product: product,
          quantity: item.quantity,
          price_at_purchase: product.price
        )
        product.decrement!(:quantity, item.quantity)
      end

      @camper.decrement!(:balance, total)
      @cart.cart_items.destroy_all
    end

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: { ok: true, total: total.to_f } }
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Checkout failed: #{e.message}" }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  private

  def set_camper
    @camper = Camper.find(params[:camper_id])
  end
end
