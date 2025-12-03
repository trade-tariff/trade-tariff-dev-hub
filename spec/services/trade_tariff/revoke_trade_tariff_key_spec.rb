RSpec.describe TradeTariff::RevokeTradeTariffKey do
  subject(:revoke_trade_tariff_key) { described_class.new }

  let(:trade_tariff_key) { create(:trade_tariff_key) }

  describe "#call" do
    it "marks the Trade Tariff key as revoked" do
      revoke_trade_tariff_key.call(trade_tariff_key)

      expect(trade_tariff_key.reload).to be_revoked
    end

    it "can be called multiple times safely" do
      revoke_trade_tariff_key.call(trade_tariff_key)
      revoke_trade_tariff_key.call(trade_tariff_key)

      expect(TradeTariffKey.exists?(trade_tariff_key.id)).to be true
    end
  end
end
