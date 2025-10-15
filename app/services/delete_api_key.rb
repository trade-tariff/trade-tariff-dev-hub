class DeleteApiKey
  def initialize(api_gateway_client = nil)
    @api_gateway_client = api_gateway_client || Aws::APIGateway::Client.new
  end

  def call(api_key)
    begin
      result = @api_gateway_client.delete_api_key(api_key: api_key.api_gateway_id)

      unless result.successful?
        Rails.logger.warn("[DeleteApiKey] API Gateway deletion returned unsuccessful result")
      end
    rescue Aws::APIGateway::Errors::NotFoundException => e
      Rails.logger.warn("[DeleteApiKey] API key not found in API Gateway (#{e.message}), but deleting from database anyway")
    rescue StandardError => e
      Rails.logger.error("[DeleteApiKey] Error deleting API key: #{e.class} - #{e.message}")
      raise
    end

    api_key.destroy! if api_key.persisted?
    api_key
  end
end
