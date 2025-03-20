class RevokeApiKey
  def initialize(api_gateway_client = Aws::APIGateway::Client.new)
    @api_gateway_client = api_gateway_client
  end

  def call(api_key)
    result = update_api_gateway(api_key)

    api_key.enabled = false
    api_key.save! if result.successful?

    api_key
  rescue StandardError => e
    Rails.logger.error("Error updating API key: #{e.message}")

    raise
  end

private

  def update_api_gateway(api_key)
    @api_gateway_client.update_api_key(
      api_key: api_key.api_gateway_id,
      patch_operations: [
        {
          op: "replace",
          path: "/enabled",
          value: "false",
        },
      ],
    )
  end
end
