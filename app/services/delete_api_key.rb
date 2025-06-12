class DeleteApiKey
  def initialize(api_gateway_client = Aws::APIGateway::Client.new)
    @api_gateway_client = api_gateway_client
  end

  def call(api_key)
    result = @api_gateway_client.delete_api_key(api_key: api_key.api_gateway_id)

    api_key.destroy! if result.successful? && api_key.persisted?

    api_key
  rescue StandardError => e
    Rails.logger.error("Error deleting API key: #{e.message}")

    raise
  end
end
