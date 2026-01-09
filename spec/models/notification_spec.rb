RSpec.describe Notification do
  it { is_expected.to be_a(ActiveModel::Model) }
  it { is_expected.to respond_to(:email, :template_id, :email_reply_to_id, :personalisation) }

  describe "#reference" do
    subject(:reference) { described_class.new.reference }

    it { is_expected.to match(/\APORTAL-[A-Z0-9]{10}\z/) }
  end

  describe ".build_for_invitation" do
    subject(:notification) { described_class.build_for_invitation(invitation) }

    let(:invitation) { build(:invitation) }

    let(:expected_personalisation) do
      {
        inviter_email_address: invitation.user.email_address,
        invitation_url: TradeTariffDevHub.govuk_app_domain,
        support_email: TradeTariffDevHub.application_support_email,
      }
    end

    it "builds a notification with the correct attributes", :aggregate_failures do
      expect(notification.email).to eq(invitation.invitee_email)
      expect(notification.template_id).to eq(Notification::INVITATION_TEMPLATE_ID)
      expect(notification.personalisation).to eq(expected_personalisation)
    end
  end

  describe ".build_for_role_request" do
    subject(:notification) { described_class.build_for_role_request(role_request) }

    let(:organisation) { create(:organisation, organisation_name: "Test Organisation") }
    let(:user) { create(:user, organisation: organisation, email_address: "requester@example.com") }
    let(:role) { Role.find_by(name: "fpo:full") }
    let(:role_request) { create(:role_request, organisation: organisation, user: user, role_name: "fpo:full", note: "I need access") }

    let(:expected_personalisation) do
      {
        organisation_name: organisation.organisation_name,
        requester_email: user.email_address,
        role_name: "fpo:full",
        role_description: role.description,
        note: "I need access",
        admin_url: "#{TradeTariffDevHub.govuk_app_domain}/admin/role_requests",
      }
    end

    it "builds a notification with the correct attributes", :aggregate_failures do
      expect(notification.email).to eq(TradeTariffDevHub.role_request_email)
      expect(notification.template_id).to eq(Notification::ROLE_REQUEST_TEMPLATE_ID)
      expect(notification.personalisation).to eq(expected_personalisation)
    end

    context "when note is blank" do
      let(:role_request) { create(:role_request, organisation: organisation, user: user, role_name: "fpo:full", note: nil) }

      it "uses default note text" do
        expect(notification.personalisation[:note]).to eq("No note provided")
      end
    end

    context "when role description is missing" do
      let(:role_request) { create(:role_request, organisation: organisation, user: user, role_name: "fpo:full", note: "Test") }

      before do
        allow(Role).to receive(:find_by).with(name: "fpo:full").and_return(nil)
      end

      it "falls back to role name" do
        expect(notification.personalisation[:role_description]).to eq("fpo:full")
      end
    end
  end

  describe ".build_for_role_request_approved" do
    subject(:notification) { described_class.build_for_role_request_approved(role_request) }

    let(:organisation) { create(:organisation, organisation_name: "Test Organisation") }
    let(:user) { create(:user, organisation: organisation, email_address: "requester@example.com") }
    let(:role) { Role.find_by(name: "fpo:full") }
    let(:role_request) { create(:role_request, organisation: organisation, user: user, role_name: "fpo:full") }

    let(:expected_personalisation) do
      {
        organisation_name: organisation.organisation_name,
        role_name: "fpo:full",
        role_description: role.description,
        organisation_url: "#{TradeTariffDevHub.govuk_app_domain}/organisations/#{organisation.id}",
      }
    end

    it "builds a notification with the correct attributes", :aggregate_failures do
      expect(notification.email).to eq(user.email_address)
      expect(notification.template_id).to eq(Notification::ROLE_REQUEST_APPROVED_TEMPLATE_ID)
      expect(notification.personalisation).to eq(expected_personalisation)
    end

    context "when role description is missing" do
      let(:role_request) { create(:role_request, organisation: organisation, user: user, role_name: "fpo:full") }

      before do
        allow(Role).to receive(:find_by).with(name: "fpo:full").and_return(nil)
      end

      it "falls back to role name" do
        expect(notification.personalisation[:role_description]).to eq("fpo:full")
      end
    end
  end
end
