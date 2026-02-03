RSpec.describe AssociateUserToOrganisation do
  subject(:service) { described_class.new }

  describe "#call" do
    context "when the user already has an organisation" do
      let!(:user) { create(:user) }

      it "does not change the user's organisation" do
        expect { service.call(user) }.not_to(change { user.reload.organisation })
      end

      it "returns nil" do
        expect(service.call(user)).to be_nil
      end

      it "does not create any new organisations" do
        expect { service.call(user) }.not_to change(Organisation, :count)
      end
    end

    context "when the user does not have an organisation and a pending invitation exists" do
      let(:user) { build(:user, organisation: nil, email_address: "invitee@example.com") }
      let(:inviter) { create(:user) }
      let!(:invitation) do
        create(
          :invitation,
          invitee_email: user.email_address,
          organisation: inviter.organisation,
          status: :pending,
          user: inviter,
        )
      end

      it "associates the user with the invitation's organisation" do
        service.call(user)

        expect(user.organisation).to eq(inviter.organisation)
      end

      it "marks the invitation as accepted" do
        expect { service.call(user) }.to change { invitation.reload.status }.from("pending").to("accepted")
      end

      it "saves the user" do
        service.call(user)

        expect(user).to be_persisted
      end

      it "does not create a new organisation" do
        expect { service.call(user) }.not_to change(Organisation, :count)
      end

      it "increments the accepted invitations count" do
        expect { service.call(user) }.to change { Invitation.accepted.count }.by(1)
      end
    end

    context "when the user does not have an organisation and no invitation exists" do
      let(:user) { build(:user, organisation: nil, email_address: "noinvite@example.com") }

      it "raises an InvitationRequiredError" do
        expect { service.call(user) }.to raise_error(
          described_class::InvitationRequiredError,
          "No pending invitation found for noinvite@example.com",
        )
      end

      it "does not save the user", :aggregate_failures do
        expect { service.call(user) }.to raise_error(described_class::InvitationRequiredError)

        expect(user).not_to be_persisted
      end

      it "does not create any organisations" do
        expect {
          begin
            service.call(user)
          rescue StandardError
            nil
          end
        }.not_to change(Organisation, :count)
      end
    end

    context "when the user does not have an organisation and only a revoked invitation exists" do
      let(:user) { build(:user, organisation: nil, email_address: "revoked@example.com") }
      let(:inviter) { create(:user) }

      before do
        create(
          :invitation,
          invitee_email: user.email_address,
          organisation: inviter.organisation,
          status: :revoked,
          user: inviter,
        )
      end

      it "raises an InvitationRequiredError" do
        expect { service.call(user) }.to raise_error(
          described_class::InvitationRequiredError,
          "No pending invitation found for revoked@example.com",
        )
      end
    end

    context "when the user does not have an organisation and only an accepted invitation exists" do
      let(:user) { build(:user, organisation: nil, email_address: "accepted@example.com") }
      let(:inviter) { create(:user) }

      before do
        create(
          :invitation,
          invitee_email: user.email_address,
          organisation: inviter.organisation,
          status: :accepted,
          user: inviter,
        )
      end

      it "raises an InvitationRequiredError" do
        expect { service.call(user) }.to raise_error(
          described_class::InvitationRequiredError,
          "No pending invitation found for accepted@example.com",
        )
      end
    end

    context "when the user does not have an organisation and multiple invitations exist for different emails" do
      let(:user) { build(:user, organisation: nil, email_address: "target@example.com") }
      let(:inviter) { create(:user) }
      let(:other_organisation) { create(:organisation) }

      before do
        create(
          :invitation,
          invitee_email: "other@example.com",
          organisation: other_organisation,
          status: :pending,
          user: create(:user, organisation: other_organisation),
        )
      end

      it "raises an InvitationRequiredError" do
        expect { service.call(user) }.to raise_error(
          described_class::InvitationRequiredError,
          "No pending invitation found for target@example.com",
        )
      end
    end

    context "when the user save fails during transaction" do
      let(:user) { build(:user, organisation: nil, email_address: "failing@example.com") }
      let(:inviter) { create(:user) }
      let!(:invitation) do
        create(
          :invitation,
          invitee_email: user.email_address,
          organisation: inviter.organisation,
          status: :pending,
          user: inviter,
        )
      end

      before do
        allow(user).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "raises the error" do
        expect { service.call(user) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "rolls back the invitation status change", :aggregate_failures do
        expect { service.call(user) }.to raise_error(ActiveRecord::RecordInvalid)

        expect(invitation.reload.status).to eq("pending")
      end
    end

    context "when invitation accepted! fails during transaction" do
      let(:user) { build(:user, organisation: nil, email_address: "failing@example.com") }
      let(:inviter) { create(:user) }
      let!(:invitation) do
        create(
          :invitation,
          invitee_email: user.email_address,
          organisation: inviter.organisation,
          status: :pending,
          user: inviter,
        )
      end

      before do
        allow(invitation).to receive(:accepted!).and_raise(ActiveRecord::RecordInvalid)
        allow(Invitation).to receive(:find_by).and_return(invitation)
      end

      it "raises the error" do
        expect { service.call(user) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not persist the user", :aggregate_failures do
        expect { service.call(user) }.to raise_error(ActiveRecord::RecordInvalid)

        expect(user).not_to be_persisted
      end
    end
  end
end
