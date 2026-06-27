class CampersController < ApplicationController
  def index
    @campers = Camper.order(:name)
  end

  def show
    @camper = Camper.find(params[:id])
    @purchases = @camper.purchases.includes(:product).order(created_at: :desc)
    @cart = @camper.cart_or_create
    @products_by_section = Product.available.order(:section, :name).group_by(&:section)
  end
end
