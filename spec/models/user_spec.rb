require "rails_helper"

RSpec.describe User, type: :model do
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe ".from_profile!" do
    subject(:from_profile!) { described_class.from_profile!(profile) }

    let!(:user) { create(:user) }

    context "when the matching organisation and user are found" do
      let(:profile) do
        {
          "sub" => user.user_id,
          "bas:groupId" => user.organisation.organisation_id,
          "email" => user.email_address,
        }
      end

      it { is_expected.to eq(user) }
      it { expect { from_profile! }.not_to change(described_class, :count) }
      it { expect { from_profile! }.not_to change(Organisation, :count) }
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
      it { expect { from_profile! }.to change(Organisation, :count).by(1) }
    end
  end

  describe "#application_reference" do
    subject { user.application_reference }

    let(:user) do
      create(
        :user,
        organisation: create(
          :organisation,
          application_reference: "foo",
        ),
      )
    end

    it { is_expected.to eq("foo") }
  end
end
