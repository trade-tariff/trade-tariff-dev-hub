RSpec.describe ApiKey, type: :model do
  let(:organisation) { create(:organisation) }

  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe "#limit_keys_per_organisation" do
    context "when in production environment" do
      before do
        allow(TradeTariffDevHub).to receive(:production_environment?).and_return(true)
      end

      shared_examples "allows up to 3 keys" do |key_count, expected_validity|
        let(:api_key) { build(:api_key, organisation: organisation, enabled: true) }

        before do
          create_list(:api_key, key_count, organisation: organisation)
        end

        it { expect(api_key.valid?).to eq(expected_validity) }
      end

      it_behaves_like "allows up to 3 keys", 0, true
      it_behaves_like "allows up to 3 keys", 1, true
      it_behaves_like "allows up to 3 keys", 2, true
      it_behaves_like "allows up to 3 keys", 3, false

      it "counts only active keys toward the limit (revoked keys do not block new ones)" do
        create_list(:api_key, 2, organisation: organisation, enabled: true)
        create_list(:api_key, 1, organisation: organisation, enabled: false)
        api_key = build(:api_key, organisation: organisation, enabled: true)
        expect(api_key).to be_valid
      end

      it "adds limit exceeded error when at active key limit" do
        create_list(:api_key, 3, organisation: organisation, enabled: true)
        api_key = build(:api_key, organisation: organisation, enabled: true)
        api_key.valid?
        expect(api_key.errors[:base]).to include("Organisation can have a maximum of 3 active API keys")
      end

      it "does not count itself when updating an existing key" do
        existing_keys = create_list(:api_key, 3, organisation: organisation)
        key_to_update = existing_keys.first
        key_to_update.description = "Updated description"
        expect(key_to_update).to be_valid
      end

      it "allows admin organisation to have more than 3 API keys" do
        admin_organisation = create(:organisation, :admin)
        create_list(:api_key, 3, organisation: admin_organisation)
        api_key = build(:api_key, organisation: admin_organisation, enabled: true)
        expect(api_key).to be_valid
      end

      it "allows admin organisation to have many API keys" do
        admin_organisation = create(:organisation, :admin)
        create_list(:api_key, 10, organisation: admin_organisation)
        api_key = build(:api_key, organisation: admin_organisation, enabled: true)
        expect(api_key).to be_valid
      end

      it "skips validation when key is disabled" do
        create_list(:api_key, 3, organisation: organisation)
        disabled_key = build(:api_key, organisation: organisation, enabled: false)
        expect(disabled_key).to be_valid
      end
    end

    context "when in development or test environment" do
      before do
        allow(TradeTariffDevHub).to receive(:production_environment?).and_return(false)
      end

      it "allows creating unlimited keys when not in production" do
        create_list(:api_key, 10, organisation: organisation)
        api_key = build(:api_key, organisation: organisation, enabled: true)
        expect(api_key).to be_valid
      end

      it "allows creating keys even when disabled in development" do
        create_list(:api_key, 10, organisation: organisation)
        disabled_key = build(:api_key, organisation: organisation, enabled: false)
        expect(disabled_key).to be_valid
      end
    end
  end
end
