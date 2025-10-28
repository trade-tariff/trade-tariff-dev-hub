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
end
