# frozen_string_literal: true

module Identity
  class ClientCredentialsApi
    # Maps dev-hub scope names to identity/OAuth scope names.
    SCOPE_MAP = {
      "read" => "tariff/read",
      "categorisation" => "tariff/categorisation",
      "fpo" => "tariff/fpo"
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
        client_id = body["client_id"]
        client_secret = body["client_secret"]
        if client_id.blank? || client_secret.blank?
          raise Error, "Identity API returned 201 but response missing client_id or client_secret"
        end

        CreateResult.new(client_id: client_id, client_secret: client_secret)
      when 400, 401, 404, 422, 502, 503
        raise Error, "Identity API error #{response.status}: #{error_body_excerpt(response.body)}"
      else
        raise Error, "Identity API unexpected response #{response.status}: #{error_body_excerpt(response.body)}"
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
        raise Error, "Identity API error #{response.status}: #{error_body_excerpt(response.body)}"
      else
        raise Error, "Identity API unexpected response #{response.status}: #{error_body_excerpt(response.body)}"
      end
    end

    class Error < StandardError; end

  private

    def error_body_excerpt(body, max_length = 200)
      text = case body
             when String
               body
             when Hash, Array
               JSON.generate(body)
             when nil
               ""
             else
               body.to_s
             end

      text.truncate(max_length)
    rescue StandardError
      body.to_s.truncate(max_length)
    end

    def http_client
      cert_path = "/tmp/backend.crt"
      File.write(cert_path, ENV["SSL_CERT_PEM"]&.gsub('\\n', "\n"))

      @http_client ||= Faraday.new(url: TradeTariffDevHub.identity_client_credentials_api_url) do |conn|
        conn.request :json
        conn.response :json
        conn.adapter Faraday.default_adapter
        conn.response :logger if Rails.logger.debug?
        conn.ssl.verify = false
        conn.ssl.ca_file = cert_path
        conn.headers["Authorization"] = "Bearer #{TradeTariffDevHub.identity_api_key}"
      end
    end
  end
end
