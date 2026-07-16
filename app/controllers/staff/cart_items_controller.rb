class Staff::CartItemsController < ApplicationController
  before_action :set_staff_member

  def create
    @cart = @staff_member.cart_or_create
    product = Product.find(params[:product_id])
    cart_item = @cart.cart_items.find_by(product: product)

    if cart_item
      cart_item.increment!(:quantity)
    else
      @cart.cart_items.create!(product: product, quantity: 1)
    end

    redirect_to staff_member_path(@staff_member)
  end

  def update
    @cart = @staff_member.cart_or_create
    cart_item = @cart.cart_items.find(params[:id])

    if params[:direction] == "up"
      cart_item.increment!(:quantity)
    else
      if cart_item.quantity > 1
        cart_item.decrement!(:quantity)
      else
        cart_item.destroy
      end
    end

    redirect_to staff_member_path(@staff_member)
  end

  def destroy
    @cart = @staff_member.cart_or_create
    cart_item = @cart.cart_items.find(params[:id])
    cart_item.destroy
    redirect_to staff_member_path(@staff_member)
  end

  private

  def set_staff_member
    @staff_member = StaffMember.find(params[:staff_member_id])
  end
end
