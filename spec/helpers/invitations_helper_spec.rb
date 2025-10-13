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

    context "when status is declined" do
      let(:status) { "declined" }

      it { is_expected.to eq("<strong class=\"govuk-tag govuk-tag--red\">Declined</strong>") }
    end

    context "when status is expired" do
      let(:status) { "expired" }

      it { is_expected.to eq("<strong class=\"govuk-tag govuk-tag--grey\">Expired</strong>") }
    end

    context "when status is revoked" do
      let(:status) { "revoked" }

      it { is_expected.to eq("<strong class=\"govuk-tag govuk-tag--grey\">Revoked</strong>") }
    end
  end

  describe "#invitation_actions_for" do
    subject { helper.invitation_actions_for(invitation) }

    let(:invitation) { create(:invitation, invitee_email: "foo@baz.com", status:) }

    shared_examples_for "no actions" do |status|
      let(:status) { status }
      it { is_expected.to be_empty }
    end

    context "when status is pending" do
      let(:status) { "pending" }

      it { is_expected.to include("Resend") }
      it { is_expected.to include("Revoke") }
      it { is_expected.to include(resend_invitation_path(invitation)) }
      it { is_expected.to include(revoke_invitation_path(invitation)) }
    end

    context "when status is expired" do
      let(:status) { "expired" }

      it { is_expected.to include("Resend") }
      it { is_expected.not_to include("Revoke") }
      it { is_expected.to include(resend_invitation_path(invitation)) }
    end

    it_behaves_like "no actions", "accepted"
    it_behaves_like "no actions", "declined"
    it_behaves_like "no actions", "revoked"
  end
end
