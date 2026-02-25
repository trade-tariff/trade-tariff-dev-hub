# frozen_string_literal: true

class TradeTariff::DeleteTradeTariffKey
  def initialize(identity_client: nil, api_gateway_client: nil)
    @identity_client = identity_client || Identity::ClientCredentialsApi.new
    @api_gateway_client = api_gateway_client || Aws::APIGateway::Client.new
  end

  def call(trade_tariff_key)
    # Delete from DB first so this app stays the source of truth; then clean up identity/API Gateway.
    # If external delete fails we only log—no DB rollback; orphan in Cognito/API Gateway is operational follow-up.
    api_gateway_id = trade_tariff_key.api_gateway_id
    client_id = trade_tariff_key.client_id
    trade_tariff_key.destroy!

    if api_gateway_id.present?
      delete_from_api_gateway(api_gateway_id)
      delete_from_identity(client_id)
    end

    trade_tariff_key
  end

private

  def delete_from_api_gateway(api_gateway_id)
    @api_gateway_client.delete_api_key(api_key: api_gateway_id)
  rescue Aws::APIGateway::Errors::NotFoundException
    Rails.logger.warn("[DeleteTradeTariffKey] API key #{api_gateway_id} not found in API Gateway, continuing")
  rescue StandardError => e
    Rails.logger.error("[DeleteTradeTariffKey] Failed to delete API key #{api_gateway_id}: #{e.message}")
  end

  def delete_from_identity(client_id)
    @identity_client.delete(client_id)
  rescue StandardError => e
    Rails.logger.error("[DeleteTradeTariffKey] Failed to delete Cognito client #{client_id}: #{e.message}")
  end
end
