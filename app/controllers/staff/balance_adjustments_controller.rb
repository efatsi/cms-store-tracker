class Staff::BalanceAdjustmentsController < ApplicationController
  before_action :set_staff_member

  def create
    amount = params[:amount].to_d
    direction = params[:direction]
    signed_amount = direction == "decrease" ? -amount.abs : amount.abs

    adjustment = @staff_member.staff_balance_adjustments.build(amount: signed_amount, notes: params[:notes].presence)
    if adjustment.save
      redirect_to staff_member_path(@staff_member), notice: "Spent amount updated."
    else
      redirect_to staff_member_path(@staff_member), alert: "Invalid adjustment."
    end
  end

  def destroy
    adjustment = @staff_member.staff_balance_adjustments.find(params[:id])
    adjustment.destroy!
    redirect_to staff_member_path(@staff_member), notice: "Adjustment removed."
  rescue => e
    redirect_to staff_member_path(@staff_member), alert: e.message
  end

  private

  def set_staff_member
    @staff_member = StaffMember.find(params[:staff_member_id])
  end
end
