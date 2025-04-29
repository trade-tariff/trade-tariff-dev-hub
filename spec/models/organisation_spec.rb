require "rails_helper"

RSpec.describe Organisation, type: :model do
  subject(:organisation) { build(:organisation) }

  let(:expected_enum) do
    {
      unregistered: 0,
      authorised: 1,
      pending: 2,
      rejected: 3,
    }
  end

  it { is_expected.to define_enum_for(:status).with_values(expected_enum) }
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe ".from_profile!" do
    subject(:from_profile!) { described_class.from_profile!(profile) }

    let!(:user) { create(:user) }
    let(:organisation) { user.organisation }

    context "when the matching organisation are found" do
      let(:profile) do
        {
          "sub" => user.user_id,
          "bas:groupId" => user.organisation.organisation_id,
          "email" => user.email_address,
        }
      end

      it { is_expected.to eq(organisation) }
      it { expect { from_profile! }.not_to change(described_class, :count) }
    end

    context "when the matching organisation is not found" do
      let(:profile) do
        {
          "sub" => "foo",
          "bas:groupId" => "bar",
          "email" => "baz",
        }
      end

      it { expect { from_profile! }.to change(described_class, :count).by(1) }
    end
  end
end
