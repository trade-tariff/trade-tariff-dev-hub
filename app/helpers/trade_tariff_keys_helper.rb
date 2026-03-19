module TradeTariffKeysHelper
  def mask_trade_tariff_key(trade_tariff_key)
    return "****" if trade_tariff_key.client_id.blank?

    "#{trade_tariff_key.client_id[0..3]}****#{trade_tariff_key.client_id[-4..]}"
  end

  def trade_tariff_key_status(trade_tariff_key)
    trade_tariff_key.active? ? "Active" : "Revoked"
  end

  def creation_date(trade_tariff_key)
    trade_tariff_key.created_at.strftime("%d %B %Y")
  end

  # Builds the example curl command to exchange client_id and client_secret for an access token.
  # Values are form-encoded so the command is safe to copy and run.
  def trade_tariff_curl_example(token_endpoint, client_id, client_secret)
    form_body = "grant_type=client_credentials&client_id=#{CGI.escape(client_id)}&client_secret=#{CGI.escape(client_secret)}"
    <<~CURL.strip
      curl --request POST "#{token_endpoint}" \\
        -H "Content-Type: application/x-www-form-urlencoded" \\
        -d "#{form_body}"
    CURL
  end
end
