RSpec.describe Session, type: :model do
  describe "validations" do
    subject(:session) { build(:session) }

    it { is_expected.to validate_presence_of(:id_token) }
    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token) }
  end

  describe "#renew?" do
    it "returns true when the token cannot be verified" do
      session = build(:session)
      invalid_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :invalid)
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: invalid_result))

      expect(session.renew?).to be(true)
    end

    it "returns false when the token is valid" do
      session = build(:session)
      payload = { "sub" => "12345", "exp" => 1.day.from_now.to_i }
      valid_result = VerifyToken::Result.new(valid: true, payload: payload, reason: nil)
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: valid_result))

      expect(session.renew?).to be(false)
    end
  end
end
