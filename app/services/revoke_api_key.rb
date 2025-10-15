class RevokeApiKey
  def initialize(api_gateway_client = nil)
    @api_gateway_client = api_gateway_client || Aws::APIGateway::Client.new
  end

  def call(api_key)
    begin
      result = update_api_gateway(api_key)

      unless result.successful?
        Rails.logger.warn("[RevokeApiKey] API Gateway update returned unsuccessful result, but continuing with database update")
      end
    rescue Aws::APIGateway::Errors::NotFoundException => e
      Rails.logger.warn("[RevokeApiKey] API key not found in API Gateway (#{e.message}), but updating database anyway")
    rescue StandardError => e
      Rails.logger.error("[RevokeApiKey] Error updating API key: #{e.class} - #{e.message}")
      raise
    end

    api_key.enabled = false
    api_key.save!
    api_key
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
