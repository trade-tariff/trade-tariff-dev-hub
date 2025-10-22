RSpec.describe ApiKeysHelper, type: :helper do
  describe "#mask_api_key" do
    subject { helper.mask_api_key(api_key) }

    let(:api_key_id) { api_key.api_key_id }
    let(:api_key) { create(:api_key) }

    it { is_expected.to eq("****#{api_key_id[-4..]}") }
  end

  describe "#api_key_status" do
    subject { helper.api_key_status(api_key) }

    let(:api_key) { create(:api_key, enabled:) }

    context "when enabled" do
      let(:enabled) { true }

      it { is_expected.to eq("Active") }
    end

    context "when disabled" do
      let(:enabled) { false }

      it { is_expected.to eq("Revoked on #{api_key.updated_at.to_date.to_formatted_s(:govuk)}") }
    end
  end
end
