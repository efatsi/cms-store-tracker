class ProductsController < ApplicationController
  before_action :set_product, only: [:edit, :update, :destroy]

  def index
    purchase_counts = Purchase.group(:product_id).count
    @products = Product.order(:section, :name).map { |p| [p, purchase_counts[p.id] || 0] }
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    respond_to do |format|
      if @product.save
        format.html { redirect_to products_path, notice: "\"#{@product.name}\" added." }
        format.json { render json: { id: @product.id, name: @product.name }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { error: @product.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @product.update(product_params)
      redirect_to products_path, notice: "\"#{@product.name}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @product.name
    ActiveRecord::Base.transaction do
      @product.purchases.includes(:camper).each do |purchase|
        purchase.camper.increment!(:balance, purchase.subtotal)
      end
      @product.destroy!
    end
    redirect_to products_path, notice: "\"#{name}\" deleted."
  rescue => e
    redirect_to products_path, alert: e.message
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :price, :quantity, :section)
  end
end
