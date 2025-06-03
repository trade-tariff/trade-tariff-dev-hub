RSpec.describe Session, type: :model do
  describe "validations" do
    subject(:session) { build(:session) }

    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_presence_of(:expires_at) }
    it { is_expected.to validate_uniqueness_of(:token) }
  end

  describe "#raw_info" do
    subject(:session) { build(:session) }

    it { expect(session.raw_info).to be_a(Hashie::Mash) }
  end

  describe "#update_profile_url" do
    subject(:update_profile_url) { build(:session, raw_info: { profile: "https://example.com/profile" }).update_profile_url }

    it { is_expected.to eq("https://example.com/profile") }
  end

  describe "#manage_team_url" do
    subject(:manage_team_url) { build(:session, raw_info: { "bas:groupProfile" => "https://example.com/team" }).manage_team_url }

    it { is_expected.to eq("https://example.com/team") }
  end

  describe "#email_address" do
    subject(:email_address) { build(:session, raw_info: { email: "bas@qux.com" }).email_address }

    it { is_expected.to eq("bas@qux.com") }
  end

  describe "#organisation_account?" do
    context "when manage_team_url is present" do
      subject(:session) { build(:session, raw_info: { "bas:groupProfile" => "https://example.com/team" }) }

      it { is_expected.to be_organisation_account }
    end

    context "when manage_team_url is not present" do
      subject(:session) { build(:session, raw_info: {}) }

      it { is_expected.not_to be_organisation_account }
    end
  end

  describe "#expired?" do
    context "when the expires_at is before now" do
      subject(:session) { build(:session, expires_at: 1.hour.ago) }

      it { is_expected.to be_expired }
    end

    context "when the expires_at is after now" do
      subject(:session) { build(:session, expires_at: 1.hour.from_now) }

      it { is_expected.not_to be_expired }
    end
  end
end
