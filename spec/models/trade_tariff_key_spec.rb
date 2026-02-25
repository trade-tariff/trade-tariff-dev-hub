RSpec.describe TradeTariffKey, type: :model do
  subject { build(:trade_tariff_key) }

  let(:organisation) { create(:organisation) }

  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  it { is_expected.to belong_to(:organisation) }

  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_uniqueness_of(:client_id) }
  it { is_expected.to validate_presence_of(:scopes) }

  describe "#limit_keys_per_organisation" do
    context "when in production environment" do
      before do
        allow(TradeTariffDevHub).to receive(:production_environment?).and_return(true)
      end

      shared_examples "allows up to 3 keys" do |key_count, expected_validity|
        let(:trade_tariff_key) { build(:trade_tariff_key, organisation: organisation) }

        before do
          create_list(:trade_tariff_key, key_count, organisation: organisation)
        end

        it { expect(trade_tariff_key.valid?).to eq(expected_validity) }
      end

      it_behaves_like "allows up to 3 keys", 0, true
      it_behaves_like "allows up to 3 keys", 1, true
      it_behaves_like "allows up to 3 keys", 2, true
      it_behaves_like "allows up to 3 keys", 3, false

      it "does not count itself when updating an existing key" do
        existing_keys = create_list(:trade_tariff_key, 3, organisation: organisation)
        key_to_update = existing_keys.first
        key_to_update.description = "Updated description"
        expect(key_to_update).to be_valid
      end

      it "skips validation when key is disabled" do
        create_list(:trade_tariff_key, 3, organisation: organisation)
        disabled_key = build(:trade_tariff_key, organisation: organisation, enabled: false)
        expect(disabled_key).to be_valid
      end
    end

    context "when in development or test environment" do
      before do
        allow(TradeTariffDevHub).to receive(:production_environment?).and_return(false)
      end

      it "allows creating unlimited keys when not in production" do
        create_list(:trade_tariff_key, 10, organisation: organisation)
        trade_tariff_key = build(:trade_tariff_key, organisation: organisation)
        expect(trade_tariff_key).to be_valid
      end

      it "allows creating keys even when disabled in development" do
        create_list(:trade_tariff_key, 10, organisation: organisation)
        disabled_key = build(:trade_tariff_key, organisation: organisation, enabled: false)
        expect(disabled_key).to be_valid
      end
    end
  end

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
