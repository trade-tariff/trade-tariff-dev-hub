class TradeTariff::DeleteTradeTariffKey
  def call(trade_tariff_key)
    trade_tariff_key.destroy!
  end
end
