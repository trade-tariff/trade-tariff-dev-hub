RSpec.describe TradeTariff::DeleteTradeTariffKey do
  subject(:delete_trade_tariff_key) { described_class.new }

  let(:trade_tariff_key) { create(:trade_tariff_key) }

  describe "#call" do
    it "destroys the Trade Tariff key" do
      trade_tariff_key_id = trade_tariff_key.id
      delete_trade_tariff_key.call(trade_tariff_key)

      expect(TradeTariffKey.find_by(id: trade_tariff_key_id)).to be_nil
    end

    it "removes the key from the database" do
      delete_trade_tariff_key.call(trade_tariff_key)

      expect(TradeTariffKey.count).to eq(0)
    end

    it "can be called on an already deleted key without error" do
      delete_trade_tariff_key.call(trade_tariff_key)

      expect { delete_trade_tariff_key.call(trade_tariff_key) }.not_to raise_error
    end
  end
end
