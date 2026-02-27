# frozen_string_literal: true

class TradeTariff::RevokeTradeTariffKey
  def initialize(api_gateway_client: nil)
    @api_gateway_client = api_gateway_client || Aws::APIGateway::Client.new
  end

  def call(trade_tariff_key)
    if trade_tariff_key.api_gateway_id.present?
      disable_api_gateway_key(trade_tariff_key.api_gateway_id)
    end

    trade_tariff_key.revoke!
    trade_tariff_key
  end

private

  def disable_api_gateway_key(api_gateway_id)
    @api_gateway_client.update_api_key(
      api_key: api_gateway_id,
      patch_operations: [
        { op: "replace", path: "/enabled", value: "false" },
      ],
    )
  rescue Aws::APIGateway::Errors::NotFoundException => e
    Rails.logger.warn("[RevokeTradeTariffKey] API key #{api_gateway_id} not found in API Gateway (#{e.message}), updating database anyway")
  rescue StandardError => e
    Rails.logger.warn("[RevokeTradeTariffKey] Failed to disable API key #{api_gateway_id}: #{e.message}. Revoking database record anyway.")
  end
end
