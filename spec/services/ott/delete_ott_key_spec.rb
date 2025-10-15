RSpec.describe Ott::DeleteOttKey do
  subject(:delete_ott_key) { described_class.new }

  let(:ott_key) { create(:ott_key) }

  describe "#call" do
    it "destroys the OTT key" do
      ott_key_id = ott_key.id
      delete_ott_key.call(ott_key)

      expect(OttKey.find_by(id: ott_key_id)).to be_nil
    end

    it "removes the record from the database" do
      delete_ott_key.call(ott_key)

      expect(OttKey.count).to eq(0)
    end

    it "handles already deleted keys gracefully" do
      delete_ott_key.call(ott_key)

      # Second call doesn't raise an error because the object is already destroyed
      expect { delete_ott_key.call(ott_key) }.not_to raise_error
    end
  end
end
