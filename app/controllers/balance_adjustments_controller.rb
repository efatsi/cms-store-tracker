class BalanceAdjustmentsController < ApplicationController
  before_action :set_camper

  def destroy
    adjustment = @camper.balance_adjustments.find(params[:id])
    @camper.increment!(:balance, -adjustment.amount)
    adjustment.destroy!
    redirect_to camper_path(@camper), notice: "Balance adjustment removed."
  rescue => e
    redirect_to camper_path(@camper), alert: e.message
  end

  def create
    amount = params[:amount].to_d
    direction = params[:direction]
    signed_amount = direction == "decrease" ? -amount.abs : amount.abs

    adjustment = @camper.balance_adjustments.build(amount: signed_amount, notes: params[:notes].presence)
    if adjustment.save
      @camper.increment!(:balance, signed_amount)
      redirect_to camper_path(@camper), notice: "Balance updated."
    else
      redirect_to camper_path(@camper), alert: "Invalid adjustment."
    end
  end

  private

  def set_camper
    @camper = Camper.find(params[:camper_id])
  end
end
