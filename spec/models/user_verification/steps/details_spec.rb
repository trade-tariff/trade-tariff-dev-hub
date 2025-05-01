RSpec.describe UserVerification::Steps::Details, type: :model do
  describe "validations" do
    subject(:step) do
      wizard = instance_double(UserVerification::Wizard, email_address: nil)
      store = ::WizardSteps::Store.new({})

      described_class.new(wizard, store, attributes)
    end

    let(:service) { instance_double(CheckEoriNumber, call: result) }

    let(:attributes) do
      {
        organisation_name: "Flibble Exteriors",
        eori_number: "GB12345678",
        ukacs_reference: "XIUK134123213123",
        email_address: "foo@bar.com",
      }
    end

    let(:result) { true }

    before do
      allow(CheckEoriNumber).to receive(:new).and_return(service)
    end

    it { is_expected.to be_valid }

    context "when the eori_number is not a real eori number" do
      let(:result) { false }

      it { is_expected.not_to be_valid }
    end

    context "when organisation_name is blank" do
      before { attributes.delete(:organisation_name) }

      it { is_expected.not_to be_valid }
    end

    context "when eori_number is blank" do
      before { attributes.delete(:eori_number) }

      it { is_expected.not_to be_valid }
    end

    context "when ukacs_reference is blank" do
      before { attributes.delete(:ukacs_reference) }

      it { is_expected.not_to be_valid }
    end

    context "when email_address is blank" do
      before { attributes.delete(:email_address) }

      it { is_expected.not_to be_valid }
    end
  end
end
