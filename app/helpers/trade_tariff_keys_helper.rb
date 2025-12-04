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
end
