RSpec.describe TradeTariffKey, type: :model do
  subject { build(:trade_tariff_key) }

  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  it { is_expected.to belong_to(:organisation) }

  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_uniqueness_of(:client_id) }
  it { is_expected.to validate_presence_of(:secret) }
  it { is_expected.to validate_presence_of(:scopes) }

  describe "delete_completely!" do
    it "calls TradeTariff::DeleteTradeTariffKey service" do
      trade_tariff_key = create(:trade_tariff_key)
      delete_service = instance_double(TradeTariff::DeleteTradeTariffKey, call: true)
      allow(TradeTariff::DeleteTradeTariffKey).to receive(:new).and_return(delete_service)

      trade_tariff_key.delete_completely!

      expect(TradeTariff::DeleteTradeTariffKey).to have_received(:new)
    end
  end
end
