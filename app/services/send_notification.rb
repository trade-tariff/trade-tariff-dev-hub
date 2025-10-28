class SendNotification
  PATH = "notifications".freeze

  def initialize(notification)
    @notification = notification
  end

  def call
    Rails.logger.debug("Sending notification: #{serializable}")

    response = self.class.post(PATH, serializable)

    case response.status
    when 202
      Rails.logger.info("Notification enqueued successfully: #{response.body&.dig('data', 'id')}")
      true
    when 401
      Rails.logger.error("Unauthorized to send notification: #{response.body}")
      false
    when 422
      Rails.logger.error("Validation error sending notification: #{response.body}")

      false
    else
      Rails.logger.error("Failed to send notification: #{response.status} #{response.body}")
      false
    end
  end

private

  def serializable
    NotificationSerializer.new(@notification).serializable_hash
  end

  class << self
    ACCEPT = "application/vnd.hmrc.2.0+json".freeze

    def post(path, body)
      client.post(path) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json
      end
    end

  private

    def client
      @client ||= Faraday.new(url: TradeTariffDevHub.uk_backend_url) do |conn|
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
        conn.response :logger if Rails.logger.debug?
        conn.response :json
        conn.headers["User-Agent"] = user_agent
        conn.headers["Accept"] = ACCEPT
        conn.headers["Authorization"] = "Bearer #{TradeTariffDevHub.uk_backend_bearer_token}"
      end
    end

    def user_agent
      @user_agent ||= "TradeTariffDevHub/#{TradeTariffDevHub.revision}"
    end
  end
end
