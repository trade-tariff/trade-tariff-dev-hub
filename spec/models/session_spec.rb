RSpec.describe Session, type: :model do
  let(:plain_token) { SecureRandom.uuid }

  describe "validations" do
    subject(:session) { build(:session) }

    it { is_expected.to validate_presence_of(:id_token) }
    it { is_expected.to validate_presence_of(:token) }

    it "validates uniqueness of hashed token" do
      create(:session, token: plain_token)
      duplicate = build(:session, token: plain_token)

      expect(duplicate).not_to be_valid
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

  describe ".invalidate_for_user!" do
    context "when the user has existing sessions" do
      it "destroys all sessions for that user" do
        user = create(:user)
        create_list(:session, 2, user: user)

        described_class.invalidate_for_user!(user)

        expect(described_class.where(user: user).count).to eq(0)
      end

      it "returns the number of sessions destroyed" do
        user = create(:user)
        create_list(:session, 3, user: user)

        count = described_class.invalidate_for_user!(user)

        expect(count).to eq(3)
      end

      it "does not destroy sessions belonging to other users" do
        user = create(:user)
        other_user = create(:user)
        create(:session, user: user)
        other_session = create(:session, user: other_user)

        described_class.invalidate_for_user!(user)

        expect(described_class.exists?(id: other_session.id)).to be(true)
      end
    end

    context "when the user has no existing sessions" do
      it "returns 0" do
        user = create(:user)

        count = described_class.invalidate_for_user!(user)

        expect(count).to eq(0)
      end
    end
  end

  describe "#app_session_timed_out?" do
    context "when expires_at and last_active_at are nil" do
      it "returns false" do
        session = build(:session, expires_at: nil, last_active_at: nil)

        expect(session.app_session_timed_out?).to be(false)
      end
    end

    context "when session is within absolute lifetime and recently active" do
      it "returns false" do
        session = build(:session, expires_at: 2.hours.from_now, last_active_at: 5.minutes.ago)

        expect(session.app_session_timed_out?).to be(false)
      end
    end

    context "when session has exceeded the absolute 4-hour lifetime" do
      it "returns true" do
        session = build(:session, expires_at: 1.second.ago)

        expect(session.app_session_timed_out?).to be(true)
      end
    end

    context "when session has been inactive for more than 15 minutes" do
      it "returns true" do
        session = build(:session, expires_at: 2.hours.from_now, last_active_at: 16.minutes.ago)

        expect(session.app_session_timed_out?).to be(true)
      end
    end

    context "when last_active_at is nil but expires_at is in the future" do
      it "returns false" do
        session = build(:session, expires_at: 2.hours.from_now, last_active_at: nil)

        expect(session.app_session_timed_out?).to be(false)
      end
    end

    context "when expires_at is nil but last_active_at is recent" do
      it "returns false" do
        session = build(:session, expires_at: nil, last_active_at: 5.minutes.ago)

        expect(session.app_session_timed_out?).to be(false)
      end
    end
  end

  describe "#touch_last_active!" do
    it "updates last_active_at to approximately the current time" do
      session = create(:session)
      session.touch_last_active!

      expect(session.reload.last_active_at).to be_within(2.seconds).of(Time.current)
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
