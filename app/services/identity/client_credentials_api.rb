# frozen_string_literal: true

module Identity
  class ClientCredentialsApi
    # Maps dev-hub scope names to identity/OAuth scope names.
    SCOPE_MAP = {
      "read" => "tariff/read",
      "write" => "tariff/write",
    }.freeze

    CreateResult = Struct.new(:client_id, :client_secret, keyword_init: true)

    def initialize(http_client: nil)
      @http_client = http_client
    end

    # @param scopes [Array<String>] e.g. %w[read write]
    # @return [CreateResult] struct with client_id and client_secret from identity service
    # @raise [Identity::ClientCredentialsApi::Error] on 4xx/5xx API errors
    def create!(scopes)
      identity_scopes = scopes.map { |s| SCOPE_MAP[s] || s }
      response = http_client.post("client_credentials") do |req|
        req.body = { scopes: identity_scopes }
      end

      case response.status
      when 201
        body = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
        CreateResult.new(
          client_id: body["client_id"],
          client_secret: body["client_secret"],
        )
      when 400, 401, 404, 422, 502, 503
        raise Error, "Identity API error #{response.status}: #{response.body&.truncate(200)}"
      else
        raise Error, "Identity API unexpected response #{response.status}: #{response.body&.truncate(200)}"
      end
    end

    # @param client_id [String] Cognito app client ID
    # @return [true] on 204 No Content or 404 Not Found
    # @raise [Identity::ClientCredentialsApi::Error] on other API errors
    def delete(client_id)
      response = http_client.delete("client_credentials/#{CGI.escape(client_id)}")

      case response.status
      when 204, 404
        true
      when 400, 401, 422, 502
        raise Error, "Identity API error #{response.status}: #{response.body&.truncate(200)}"
      else
        raise Error, "Identity API unexpected response #{response.status}: #{response.body&.truncate(200)}"
      end
    end

    class Error < StandardError; end

  private

    def http_client
      @http_client ||= Faraday.new(url: TradeTariffDevHub.identity_client_credentials_api_url) do |conn|
        conn.request :json
        conn.response :json
        conn.adapter Faraday.default_adapter
        conn.response :logger if Rails.logger.debug?
        conn.headers["Authorization"] = "Bearer #{TradeTariffDevHub.identity_api_token}"
      end
    end
  end
end
