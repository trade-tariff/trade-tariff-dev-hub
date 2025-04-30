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

      it { is_expected.to eq("Revoked on #{api_key.updated_at.strftime('%d %B %Y')}") }
    end
  end

  describe "#creation_date" do
    subject { helper.creation_date(api_key) }

    let(:api_key) { create(:api_key, created_at:) }

    context "when created today" do
      let(:created_at) { Time.zone.now }

      it { is_expected.to eq("Today") }
    end

    context "when created in the past" do
      let(:created_at) { Time.zone.parse("2025-04-08T10:56:20") }

      it { is_expected.to eq("08 April 2025") }
    end
  end
end
