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

  describe ".find_or_associate_implicit_organisation_to" do
    context "when the user already has an organisation" do
      subject(:find_or_associate_implicit_organisation_to) { described_class.find_or_associate_implicit_organisation_to(user) }

      let!(:user) { create(:user, organisation: create(:organisation)) }

      it { expect { find_or_associate_implicit_organisation_to }.not_to change(described_class, :count) }
    end

    context "when the user does not have an organisation" do
      subject(:find_or_associate_implicit_organisation_to) { described_class.find_or_associate_implicit_organisation_to(user) }

      let!(:user) { build(:user, organisation: nil) }

      it "creates and associates a new implicit organisation to the user", :aggregate_failures do
        expect { find_or_associate_implicit_organisation_to }.to change(described_class, :count).by(1)
        expect(user.organisation.organisation_name).to eq(user.email_address)
        expect(user.organisation.organisation_id).not_to be_nil
        expect(user.organisation.description).to include("Default implicit organisation for initial user #{user.email_address}")
        expect(user.organisation.status).to eq("unregistered")
      end
    end
  end
end
