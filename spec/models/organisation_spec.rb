RSpec.describe Organisation, type: :model do
  subject(:organisation) { build(:organisation) }

  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe "#has_role?" do
    subject(:has_role?) { organisation.has_role?("ott:full") }

    context "when the organisation has the role" do
      before { organisation.assign_role!("ott:full") }

      it { is_expected.to be true }
    end

    context "when the organisation does not have the role" do
      it { is_expected.to be false }
    end
  end

  describe "#assign_role!" do
    subject(:assign_role!) { organisation.assign_role!("ott:full") }

    let(:organisation) { create(:organisation) }

    context "when the organisation does not have the role" do
      it { expect { assign_role! }.to change(organisation.roles, :count).by(1) }
    end

    context "when the organisation already has the role" do
      before { organisation.assign_role!("ott:full") }

      it { expect { assign_role! }.not_to change(organisation.roles, :count) }
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
        expect(user.organisation.description).to include("Default implicit organisation for initial user #{user.email_address}")
      end

      it "assigns the correct roles" do
        find_or_associate_implicit_organisation_to
        expect(user.organisation.roles.pluck(:name)).to eq(%w[ott:full])
      end
    end
  end
end
