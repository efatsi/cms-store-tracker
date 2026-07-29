class CampersController < ApplicationController
  def index
    @campers = Camper.order(:name)
  end

  def balances_csv
    campers = Camper.order(:name)
    csv = CSV.generate(headers: true) do |row|
      row << ["Camper", "Balance"]
      campers.each { |c| row << [c.name, c.balance.round(2)] }
    end
    send_data csv, filename: "camper-balances-#{Date.current}.csv", type: "text/csv"
  end

  def purchase_history_csv
    campers = Camper.includes(purchases: :product).order(:name)
    csv = CSV.generate(headers: true) do |row|
      row << ["Camper / Item", "Qty", "Price"]
      campers.each do |camper|
        purchases = camper.purchases.sort_by(&:created_at)
        next if purchases.empty?
        row << [camper.name, nil, nil]
        purchases.each do |p|
          row << [p.product.name, p.quantity, p.price_at_purchase.round(2)]
        end
      end
    end
    send_data csv, filename: "camper-purchase-history-#{Date.current}.csv", type: "text/csv"
  end

  def show
    @camper = Camper.find(params[:id])
    @products_by_section = Product.order(:section, :name).group_by(&:section)
    @cart_items = @camper.cart_or_create.cart_items.includes(:product)
    @purchases = @camper.purchases.includes(:product).order(created_at: :desc)
    @balance_adjustments = @camper.balance_adjustments.order(created_at: :desc)
  end
end
