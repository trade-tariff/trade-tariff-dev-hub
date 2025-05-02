RSpec.describe UserVerification::Wizard, type: :model do
  subject(:wizard) do
    store = ::WizardSteps::Store.new(store_answers)

    described_class.new(store, current_key, context:)
  end

  let(:context) do
    {
      email_address: "foo@bar.com",
      current_user: current_user,
    }
  end

  let(:current_user) { create(:user, email_address: "baz@qux.com", organisation:) }
  let(:current_key) { "review_answers" }
  let(:organisation) { create(:organisation, application_reference: "foo") }

  let(:store_answers) do
    {
      "organisation_name" => "Flibble Exteriors",
      "eori_number" => "GB12345678",
      "ukacs_reference" => "XIUK134123213123",
      "email_address" => "foo@bar.com",
    }
  end

  describe "#email_address" do
    it { expect(wizard.email_address).to eq("foo@bar.com") }
  end

  describe "#current_user" do
    it { expect(wizard.current_user).to eq(current_user) }
  end

  describe "#do_complete" do
    context "when the organisation already has an application reference" do
      let(:organisation) { create(:organisation, application_reference: "foo") }

      it { expect(wizard.do_complete).to eq("foo") }
      it { expect { wizard.do_complete }.not_to(change { organisation.reload.status }) }
    end

    context "when the organisation does not yet have an application reference" do
      include_context "with stubbed emails"

      let(:organisation) { create(:organisation, application_reference: nil, status: :unregistered) }

      it { expect { wizard.do_complete }.to(change { organisation.reload.application_reference }) }
      it { expect { wizard.do_complete }.to change { organisation.reload.eori_number }.to("GB12345678") }
      it { expect { wizard.do_complete }.to change { organisation.reload.status }.from("unregistered").to("pending") }
      it { expect { wizard.do_complete }.to change { organisation.reload.uk_acs_reference }.to("XIUK134123213123") }
      it { expect { wizard.do_complete }.to change { organisation.reload.organisation_name }.to("Flibble Exteriors") }
      it { expect { wizard.do_complete }.to change { current_user.reload.email_address }.to("foo@bar.com") }

      it "sends application complete emails to the user and support team", :aggregate_failures do
        wizard.do_complete

        expect(notifier_service).to have_received(:call).with("foo@bar.com", "bar", reference: be_present)
        expect(notifier_service).to have_received(:call).with("foo@bar.com", "foo", email: "foo@bar.com", eori: "GB12345678", organisation: "Flibble Exteriors", reference: be_present, scp_email: "foo@bar.com", ukc: "XIUK134123213123")
      end
    end
  end
end
