class Staff::PurchasesController < ApplicationController
  before_action :set_staff_member

  def create
    @cart = @staff_member.cart_or_create
    cart_items = @cart.cart_items.includes(:product)

    if cart_items.empty?
      redirect_to staff_member_path(@staff_member), alert: "Cart is empty."
      return
    end

    total = cart_items.sum { |item| item.product.price * item.quantity }

    ActiveRecord::Base.transaction do
      cart_items.each do |item|
        product = item.product
        @staff_member.purchases.create!(
          product: product,
          quantity: item.quantity,
          price_at_purchase: product.price
        )
        product.decrement!(:quantity, item.quantity)
      end

      @cart.cart_items.destroy_all
    end

    redirect_to staff_member_path(@staff_member), notice: "Purchase complete! $#{sprintf("%.2f", total)} charged."
  rescue => e
    redirect_to staff_member_path(@staff_member), alert: "Checkout failed: #{e.message}"
  end

  def destroy
    purchase = @staff_member.purchases.find(params[:id])
    ActiveRecord::Base.transaction do
      purchase.product.increment!(:quantity, purchase.quantity)
      purchase.destroy!
    end
    redirect_to staff_member_path(@staff_member), notice: "Purchase removed and stock restored."
  rescue => e
    redirect_to staff_member_path(@staff_member), alert: e.message
  end

  private

  def set_staff_member
    @staff_member = StaffMember.find(params[:staff_member_id])
  end
end
