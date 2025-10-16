RSpec.describe Session, type: :model do
  describe "validations" do
    subject(:session) { build(:session) }

    it { is_expected.to validate_presence_of(:id_token) }
    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token) }
  end

  describe "#renew?" do
    before do
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: decoded_id_token))
    end

    context "when the decoded_id_token is nil" do
      subject(:session) { build(:session) }

      let(:decoded_id_token) { nil }

      it { is_expected.to be_renew }
    end

    context "when the decoded_id_token is present" do
      subject(:session) { build(:session, expires_at: 1.hour.from_now) }

      let(:decoded_id_token) { { "sub" => "12345", "exp" => 1.day.from_now.to_i } }

      it { is_expected.not_to be_renew }
    end
  end
end
