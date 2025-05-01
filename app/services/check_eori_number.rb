class CheckEoriNumber
  def initialize(client = self.class.client)
    @client = client
  end

  def call(eori_number)
    response = @client.post(
      eori_lookup_url,
      { eoris: [eori_number] }.to_json,
      "Accept" => "application/json",
      "Content-Type" => "application/json",
    )

    response.status == 200
  rescue StandardError
    Rails.logger.error("Error while checking EORI number: #{eori_number}")
    false
  end

  delegate :eori_lookup_url, to: TradeTariffDevHub

  def self.client
    @client ||= Faraday.new do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.response :logger, Rails.logger, { headers: true, bodies: true }
      conn.adapter Faraday.default_adapter
    end
  end
end
