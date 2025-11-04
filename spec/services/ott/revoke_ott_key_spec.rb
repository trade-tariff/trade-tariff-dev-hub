RSpec.describe Ott::RevokeOttKey do
  subject(:revoke_ott_key) { described_class.new }

  let(:ott_key) { create(:ott_key, enabled: true) }

  describe "#call" do
    it "revokes the OTT key by setting enabled to false", :aggregate_failures do
      result = revoke_ott_key.call(ott_key)

      expect(result.enabled).to be(false)
      expect(result).to be_persisted
    end

    it "returns the ott_key" do
      result = revoke_ott_key.call(ott_key)

      expect(result).to eq(ott_key)
    end

    it "persists the change" do
      revoke_ott_key.call(ott_key)
      ott_key.reload

      expect(ott_key.enabled).to be(false)
    end
  end
end
