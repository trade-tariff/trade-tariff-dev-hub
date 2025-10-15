RSpec.describe Ott::RevokeOttKey do
  subject(:revoke_ott_key) { described_class.new }

  let(:ott_key) { create(:ott_key) }

  describe "#call" do
    it "marks the OTT key as revoked" do
      revoke_ott_key.call(ott_key)

      expect(ott_key.reload).to be_revoked
    end

    it "does not remove the record from the database" do
      revoke_ott_key.call(ott_key)

      expect(OttKey.exists?(ott_key.id)).to be true
    end
  end
end
