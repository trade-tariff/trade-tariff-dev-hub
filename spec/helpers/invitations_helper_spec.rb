RSpec.describe InvitationsHelper, type: :helper do
  describe "#invitation_status" do
    subject { helper.invitation_status(invitation) }

    let(:invitation) { build(:invitation, invitee_email: "foo@bar.com", status:) }

    context "when status is pending" do
      let(:status) { "pending" }

      it { is_expected.to eq("<strong class=\"govuk-tag govuk-tag--blue\">Pending</strong>") }
    end

    context "when status is accepted" do
      let(:status) { "accepted" }

      it { is_expected.to eq("<strong class=\"govuk-tag govuk-tag--green\">Accepted</strong>") }
    end

    context "when status is revoked" do
      let(:status) { "revoked" }

      it { is_expected.to eq("<strong class=\"govuk-tag govuk-tag--grey\">Revoked</strong>") }
    end
  end

  describe "#invitation_actions_for" do
    subject { helper.invitation_actions_for(invitation) }

    let(:invitation) { create(:invitation, invitee_email: "foo@baz.com", status:) }

    context "when status is pending" do
      let(:status) { "pending" }

      it { is_expected.to include("Resend") }
      it { is_expected.to include("Revoke") }
      it { is_expected.to include(resend_invitation_path(invitation)) }
      it { is_expected.to include(edit_invitation_path(invitation)) }
    end

    context "when status is revoked" do
      let(:status) { "revoked" }

      it { is_expected.to include("Delete") }
      it { is_expected.to include(delete_invitation_path(invitation)) }
      it { is_expected.not_to include("Resend") }
      it { is_expected.not_to include("Revoke") }
    end
  end
end
