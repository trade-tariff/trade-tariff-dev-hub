# frozen_string_literal: true

class TradeTariff::RevokeTradeTariffKey
  class ExternalRevokeError < StandardError; end

  def initialize(api_gateway_client: nil)
    @api_gateway_client = api_gateway_client || Aws::APIGateway::Client.new
  end

  def call(trade_tariff_key)
    if trade_tariff_key.api_gateway_id.present?
      disable_api_gateway_key!(trade_tariff_key.api_gateway_id)
    end

    trade_tariff_key.revoke!
    trade_tariff_key
  end

private

  # Only update DB after API Gateway disable succeeds, so we never show "revoked" while the key still works.
  def disable_api_gateway_key!(api_gateway_id)
    @api_gateway_client.update_api_key(
      api_key: api_gateway_id,
      patch_operations: [
        { op: "replace", path: "/enabled", value: "false" },
      ],
    )
  rescue Aws::APIGateway::Errors::NotFoundException => e
    Rails.logger.warn("[RevokeTradeTariffKey] API key #{api_gateway_id} not found in API Gateway (#{e.message})")
    raise ExternalRevokeError, "API key was not found in API Gateway. It may already have been removed. Please contact #{TradeTariffDevHub.application_support_email} if the key still works."
  rescue StandardError => e
    Rails.logger.error("[RevokeTradeTariffKey] Failed to disable API key #{api_gateway_id}: #{e.message}")
    raise ExternalRevokeError, "We could not revoke the key in the API Gateway. Please try again or contact #{TradeTariffDevHub.application_support_email}."
  end
end
