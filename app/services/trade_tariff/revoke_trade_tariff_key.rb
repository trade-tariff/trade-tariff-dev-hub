class TradeTariff::RevokeTradeTariffKey
  def call(trade_tariff_key)
    trade_tariff_key.revoke!
  end
end
