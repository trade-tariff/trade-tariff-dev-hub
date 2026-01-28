RSpec.describe ApiKey, type: :model do
  let(:organisation) { create(:organisation) }

  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe "validations" do
    describe "#limit_keys_per_organisation" do
      shared_examples "allows up to 3 active keys" do |active_key_count, inactive_key_count, expected_validity|
        let(:api_key) { build(:api_key, organisation: organisation) }

        before do
          create_list(:api_key, inactive_key_count, organisation: organisation, enabled: false)
          create_list(:api_key, active_key_count, organisation: organisation, enabled: true)
        end

        it { expect(api_key.valid?).to eq(expected_validity) }
      end

      it_behaves_like "allows up to 3 active keys", 0, 0, true
      it_behaves_like "allows up to 3 active keys", 1, 0, true
      it_behaves_like "allows up to 3 active keys", 2, 0, true
      it_behaves_like "allows up to 3 active keys", 3, 0, false
      it_behaves_like "allows up to 3 active keys", 2, 2, true
      it_behaves_like "allows up to 3 active keys", 2, 1, true
      it_behaves_like "allows up to 3 active keys", 3, 2, false
    end

    context "when revoking an active key at the limit" do
      let!(:api_keys) { create_list(:api_key, 3, organisation: organisation, enabled: true) }
      let(:api_key_to_revoke) { api_keys.first }

      it "skips validation when disabling a key" do
        api_key_to_revoke.enabled = false
        expect(api_key_to_revoke).to be_valid
      end
    end

    context "when organisation is an admin organisation" do
      let(:admin_organisation) { create(:organisation, :admin) }

      it "allows creating more than 3 active API keys" do
        create_list(:api_key, 3, organisation: admin_organisation, enabled: true)
        api_key = build(:api_key, organisation: admin_organisation)
        expect(api_key).to be_valid
      end

      it "allows creating many active API keys" do
        create_list(:api_key, 10, organisation: admin_organisation, enabled: true)
        api_key = build(:api_key, organisation: admin_organisation)
        expect(api_key).to be_valid
      end
    end
  end
end
