RSpec.describe Ott::RevokeOttKey do
  subject(:revoke_ott_key) { described_class.new }

  let(:ott_key) { create(:ott_key) }

  describe "#call" do
    it "destroys the OTT key", :aggregate_failures do
      ott_key_id = ott_key.id
      revoke_ott_key.call(ott_key)

      expect(OttKey.find_by(id: ott_key_id)).to be_nil
    end

    it "removes the record from the database" do
      revoke_ott_key.call(ott_key)

      expect(OttKey.count).to eq(0)
    end
  end
end
