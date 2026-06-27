class PurchasesController < ApplicationController
  before_action :set_camper

  def create
    @cart = @camper.cart_or_create
    cart_items = @cart.cart_items.includes(:product)

    if cart_items.empty?
      redirect_to camper_path(@camper), alert: "Your cart is empty."
      return
    end

    total = cart_items.sum { |item| item.product.price * item.quantity }

    if total > @camper.balance
      redirect_to camper_path(@camper), alert: "Insufficient balance. Total is $#{sprintf('%.2f', total)} but balance is $#{sprintf('%.2f', @camper.balance)}."
      return
    end

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

    redirect_to camper_path(@camper), notice: "Checkout complete! $#{sprintf('%.2f', total)} charged."
  rescue => e
    redirect_to camper_path(@camper), alert: "Checkout failed: #{e.message}"
  end

  private

  def set_camper
    @camper = Camper.find(params[:camper_id])
  end
end
