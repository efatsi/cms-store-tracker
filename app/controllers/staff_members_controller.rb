class StaffMembersController < ApplicationController
  def index
    @staff_members = StaffMember.order(:name)
    @new_staff_member = StaffMember.new
  end

  def show
    @staff_member = StaffMember.find(params[:id])
    @products_by_section = Product.order(:section, :name).group_by(&:section)
    @cart_items = @staff_member.cart_or_create.cart_items.includes(:product)
    @purchases = @staff_member.purchases.includes(:product).order(created_at: :desc)
  end

  def create
    @staff_member = StaffMember.new(staff_member_params)
    if @staff_member.save
      redirect_to staff_members_path, notice: "#{@staff_member.name} added to staff."
    else
      @staff_members = StaffMember.order(:name)
      @new_staff_member = @staff_member
      render :index, status: :unprocessable_entity
    end
  end

  private

  def staff_member_params
    params.require(:staff_member).permit(:name)
  end
end
