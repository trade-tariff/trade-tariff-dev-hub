RSpec.describe Invitation, type: :model do
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe "validations" do
    subject(:invitation) { build(:invitation) }

    it "defines a validating enum" do
      expect(invitation).to define_enum_for(:status)
        .with_values(pending: "pending", accepted: "accepted", revoked: "revoked")
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

    context "when an invitation exists with the same email but is revoked" do
      it "allows creating a new invitation" do
        create(:invitation, invitee_email: "foo@bar.com", status: "revoked")
        invitation.invitee_email = "foo@bar.com"
        expect(invitation).to be_valid
      end
    end

    context "when validating an updated record" do
      it "does not validate uniqueness of invitee_email" do
        existing_invitation = create(:invitation, invitee_email: "foo@bar.com", status: "pending")
        existing_invitation.status = "accepted"
        expect(existing_invitation).to be_valid
        existing_invitation.save!
      end
    end

    context "when the invitee_email belongs to an existing user associated with a different organisation" do
      it "adds an error indicating the user is a member elsewhere", :aggregate_failures do
        organisation = create(:organisation)
        create(:user, email_address: "foo@bar.com", organisation: organisation)
        invitation.invitee_email = "foo@bar.com"
        expect(invitation).not_to be_valid
        expect(invitation.errors[:invitee_email]).to include("This email address is already associated with a member of another organisation")
      end
    end

    context "when the invitee_email belongs to an existing user associated with the current organisation" do
      it "adds an error indicating the user is already a member", :aggregate_failures do
        user = create(:user, email_address: "foo@bar.com")
        invitation.invitee_email = "foo@bar.com"
        invitation.organisation = user.organisation
        expect(invitation).not_to be_valid
        expect(invitation.errors[:invitee_email]).to include("This email address is already associated with a member of your organisation")
      end
    end
  end
end
