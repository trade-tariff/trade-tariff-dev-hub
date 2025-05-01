RSpec.describe UserVerification::Steps::ReviewAnswers, type: :model do
  describe "validations" do
    subject(:step) do
      wizard = instance_double(UserVerification::Wizard, email_address: nil)
      store = ::WizardSteps::Store.new({})

      described_class.new(wizard, store, attributes)
    end

    let(:attributes) do
      {
        terms: ["", "1", "2", "3", "4"],
      }
    end

    it { is_expected.to be_valid }

    context "when the one or more of the terms is not checked" do
      let(:attributes) do
        {
          terms: ["", "1", "2", "4"],
        }
      end

      it { is_expected.not_to be_valid }
    end
  end
end
