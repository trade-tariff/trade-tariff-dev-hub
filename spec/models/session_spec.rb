RSpec.describe Session, type: :model do
  let(:plain_token) { SecureRandom.uuid }

  describe "validations" do
    subject(:session) { build(:session) }

    it { is_expected.to validate_presence_of(:id_token) }
    it { is_expected.to validate_presence_of(:token) }

    it "validates uniqueness of hashed token" do
      session   = create(:session, token: plain_token)
      duplicate = build(:session, token: plain_token)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to include("has already been taken")
    end
  end

  describe ".digest" do
    it "returns the hashed token" do
      token = "test1234"

      expect(described_class.digest(token)).to eq(Digest::SHA256.hexdigest(token))
    end
  end

  describe ".find_by_token" do
    context "when session exists" do
      it "finds a session by plain text token" do
        session = create(:session, token: plain_token)

        expect(described_class.find_by_token(plain_token)).to eq(session)
      end
    end

    context "when session does not exist" do
      it "returns nil" do
        expect(described_class.find_by_token("does not exist")).to be_nil
      end
    end
  end

  describe "#token=" do
    it "stores the token as a SHA256 digest" do
      session = build(:session, token: plain_token)

      expect(session.token).to eq(Digest::SHA256.hexdigest(plain_token))
    end

    it "does not store the plain token" do
      session = build(:session, token: plain_token)

      expect(session.token).not_to eq(plain_token)
    end
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
