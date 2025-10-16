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

    context "when the user does not have an organisation but an invitation exists for the user's email address" do
      subject(:find_or_associate_implicit_organisation_to) { described_class.find_or_associate_implicit_organisation_to(user) }

      let!(:user) { build(:user, organisation: nil, email_address: "foo@bar.com") }
      let(:existing_user) { create(:user, email_address: "baz@bar.com") }

      before do
        create(
          :invitation,
          invitee_email: user.email_address,
          organisation: existing_user.organisation,
          status: "pending",
          user: existing_user,
        )
      end

      it "accepts the invitation" do
        expect { find_or_associate_implicit_organisation_to }.to change { Invitation.accepted.count }.by(1)
      end

      it "associates the existing organisation to the new user", :aggregate_failures do
        expect { find_or_associate_implicit_organisation_to }.not_to change(described_class, :count)
        expect(user.organisation).to eq(existing_user.organisation)
      end

      it "does not assign any new roles" do
        expect { find_or_associate_implicit_organisation_to }.not_to change(existing_user.organisation.roles, :count)
      end

      it "does not create any new organisations" do
        expect { find_or_associate_implicit_organisation_to }.not_to change(described_class, :count)
      end
    end
  end

  describe "#admin?" do
    context "when the organisation has the admin role" do
      subject(:organisation) { create(:organisation, :admin) }

      it { is_expected.to be_admin }
    end

    context "when the organisation does not have the admin role" do
      subject(:organisation) { create(:organisation) }

      it { is_expected.not_to be_admin }
    end
  end
end
