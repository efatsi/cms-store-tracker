class CartItemsController < ApplicationController
  before_action :set_camper

  def create
    @cart = @camper.cart_or_create
    product = Product.find(params[:product_id])
    cart_item = @cart.cart_items.find_by(product: product)

    if cart_item
      cart_item.increment!(:quantity)
    else
      @cart.cart_items.create!(product: product, quantity: 1)
    end

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :ok }
    end
  end

  def update
    @cart = @camper.cart_or_create
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

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :ok }
    end
  end

  def destroy
    @cart = @camper.cart_or_create
    cart_item = @cart.cart_items.find(params[:id])
    cart_item.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :ok }
    end
  end

  private

  def set_camper
    @camper = Camper.find(params[:camper_id])
  end
end
