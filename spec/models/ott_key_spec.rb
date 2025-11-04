RSpec.describe OttKey, type: :model do
  subject { build(:ott_key) }

  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  it { is_expected.to belong_to(:organisation) }

  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_uniqueness_of(:client_id) }
  it { is_expected.to validate_presence_of(:secret) }
  it { is_expected.to validate_presence_of(:scopes) }

  describe "delete_completely!" do
    it "calls Ott::DeleteOttKey service" do
      ott_key = create(:ott_key)
      delete_service = instance_double(Ott::DeleteOttKey, call: true)
      allow(Ott::DeleteOttKey).to receive(:new).and_return(delete_service)

      ott_key.delete_completely!

      expect(Ott::DeleteOttKey).to have_received(:new)
    end
  end
end
