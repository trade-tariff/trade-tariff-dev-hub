RSpec.describe Invitation, type: :model do
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe "validations" do
    subject(:invitation) { build(:invitation) }

    it "defines a validating enum" do
      expect(invitation).to define_enum_for(:status)
        .with_values(pending: "pending", accepted: "accepted", declined: "declined", expired: "expired", revoked: "revoked")
        .with_default("pending")
        .backed_by_column_of_type(:enum)
    end

    it "validates incorrect status assignment" do
      expect { invitation.status = "invalid_status" }.to raise_error(ArgumentError, /is not a valid status/)
    end

    it "validates presence of invitee_email", :aggregate_failures do
      invitation.invitee_email = ""
      expect(invitation).not_to be_valid
      expect(invitation.errors[:invitee_email]).to include("Enter an email address")
    end

    it "validates email format", :aggregate_failures do
      invitation.invitee_email = "invalid-email"
      expect(invitation).not_to be_valid
      expect(invitation.errors[:invitee_email]).to include("Enter a properly formatted email address")
    end

    it "validates email uniqueness", :aggregate_failures do
      create(:invitation, invitee_email: "foo@bar.com")
      invitation.invitee_email = "foo@bar.com"
      expect(invitation).not_to be_valid
      expect(invitation.errors[:invitee_email]).to include("This email address has already been invited to an organisation")
    end
  end
end
