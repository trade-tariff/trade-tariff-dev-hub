# frozen_string_literal: true

class TradeTariffKeysController < AuthenticatedController
  before_action :set_trade_tariff_key, only: %i[update revoke delete]

  def index
    @trade_tariff_keys = TradeTariffKey.where(organisation_id: organisation_id).order(created_at: :desc)
  end

  def new; end

  def update
    if @trade_tariff_key.enabled
      render "revoke"
    else
      render "delete"
    end
  end

  def create
    default_scopes = %w[read write]
    @trade_tariff_key = TradeTariff::CreateTradeTariffKey.new.call(organisation_id, trade_tariff_key_params[:trade_tariff_key_description], default_scopes)
  rescue ActiveRecord::RecordInvalid => e
    @trade_tariff_key = e.record
    flash.now[:alert] = e.record.errors.full_messages.join(", ")
    render :new, status: :unprocessable_content
  rescue StandardError => e
    Rails.logger.error("Failed to create Trade Tariff key: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    flash.now[:alert] = "Failed to create Trade Tariff key. Please try again."
    @trade_tariff_key = nil
    render :new, status: :unprocessable_content
  end

  def revoke
    if @trade_tariff_key.revoked?
      redirect_to redirect_path_after_action, alert: "Trade Tariff key already revoked"
    else
      TradeTariff::RevokeTradeTariffKey.new.call(@trade_tariff_key)
      redirect_to redirect_path_after_action, notice: "Trade Tariff key revoked"
    end
  end

  def delete
    TradeTariff::DeleteTradeTariffKey.new.call(@trade_tariff_key)
    redirect_to redirect_path_after_action, notice: "Trade Tariff key deleted"
  end

private

  def set_trade_tariff_key
    @trade_tariff_key = if organisation&.admin?
                          TradeTariffKey.find_by(id: params[:id])
                        else
                          TradeTariffKey.find_by(id: params[:id], organisation_id:)
                        end

    unless @trade_tariff_key
      redirect_to redirect_path_after_action, alert: "Trade Tariff key not found"
      nil
    end
  end

  def redirect_path_after_action
    if organisation&.admin? && @trade_tariff_key && @trade_tariff_key.organisation_id != organisation.id
      admin_organisation_path(@trade_tariff_key.organisation_id)
    else
      trade_tariff_keys_path
    end
  end

  def trade_tariff_key_params
    params.permit(:trade_tariff_key_description)
  end

  def allowed_roles
    ["trade_tariff:full"]
  end
end
