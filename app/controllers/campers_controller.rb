class CampersController < ApplicationController
  def index
    @campers = Camper.order(:name)
  end

  def show
    @camper = Camper.find(params[:id])
    @products_by_section = Product.order(:section, :name).group_by(&:section)
    @cart_items = @camper.cart_or_create.cart_items.includes(:product)
    @purchases = @camper.purchases.includes(:product).order(created_at: :desc)
    @balance_adjustments = @camper.balance_adjustments.order(created_at: :desc)
  end
end
