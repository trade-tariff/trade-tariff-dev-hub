RSpec.describe Organisation, type: :model do
  subject(:organisation) { build(:organisation) }

  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe "#has_role?" do
    subject(:has_role?) { organisation.has_role?("trade_tariff:full") }

    context "when the organisation has the role" do
      before { organisation.assign_role!("trade_tariff:full") }

      it { is_expected.to be true }
    end

    context "when the organisation does not have the role" do
      it { is_expected.to be false }
    end
  end

  describe "#assign_role!" do
    subject(:assign_role!) { organisation.assign_role!("trade_tariff:full") }

    let(:organisation) { create(:organisation) }

    context "when the organisation does not have the role" do
      it { expect { assign_role! }.to change(organisation.roles, :count).by(1) }
    end

    context "when the organisation already has the role" do
      before { organisation.assign_role!("trade_tariff:full") }

      it { expect { assign_role! }.not_to change(organisation.roles, :count) }
    end
  end

  describe ".find_or_associate_implicit_organisation_to" do
    context "when the user already has an organisation" do
      subject(:find_or_associate_implicit_organisation_to) { described_class.find_or_associate_implicit_organisation_to(user) }

      let!(:user) { create(:user, organisation: create(:organisation)) }

      it { expect { find_or_associate_implicit_organisation_to }.not_to change(described_class, :count) }
    end

    # context "when the user does not have an organisation" do
    #   subject(:find_or_associate_implicit_organisation_to) { described_class.find_or_associate_implicit_organisation_to(user) }
    #
    #   let!(:user) { build(:user, organisation: nil) }
    #
    #   it "creates and associates a new implicit organisation to the user", :aggregate_failures do
    #     expect { find_or_associate_implicit_organisation_to }.to change(described_class, :count).by(1)
    #     expect(user.organisation.organisation_name).to eq(user.email_address)
    #     expect(user.organisation.description).to include("Default implicit organisation for initial user #{user.email_address}")
    #   end
    #
    #   it "assigns the correct roles" do
    #     find_or_associate_implicit_organisation_to
    #     expect(user.organisation.roles.pluck(:name)).to eq(%w[trade_tariff:full])
    #   end
    # end

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

    context "when the user does not have an organisation but an invitation exists with a non-pending status" do
      subject(:find_or_associate_implicit_organisation_to) { described_class.find_or_associate_implicit_organisation_to(user) }

      let!(:user) { build(:user, organisation: nil, email_address: "foo@bar.com") }
      let(:existing_user) { create(:user, email_address: "baz@bar.com") }

      before do
        create(
          :invitation,
          invitee_email: user.email_address,
          organisation: existing_user.organisation,
          status: :revoked,
          user: existing_user,
        )
      end

      it "raises an InvitationRequiredError" do
        expect { find_or_associate_implicit_organisation_to }.to raise_error(
          Organisation::InvitationRequiredError,
          /No pending invitation found/,
        )
      end
    end

    context "when the user does not have an organisation and no invitation exists" do
      subject(:find_or_associate_implicit_organisation_to) { described_class.find_or_associate_implicit_organisation_to(user) }

      let!(:user) { build(:user, organisation: nil, email_address: "new@user.com") }

      it "raises an InvitationRequiredError" do
        expect { find_or_associate_implicit_organisation_to }.to raise_error(
          Organisation::InvitationRequiredError,
          /No pending invitation found/,
        )
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

  describe "#implicitly_created?" do
    context "when the organisation has no roles" do
      subject(:organisation) { create(:organisation, :implicit) }

      it { is_expected.to be_implicitly_created }
    end

    context "when the organisation only has trade_tariff:full role" do
      subject(:organisation) { create(:organisation, :trade_tariff_only) }

      it { is_expected.to be_implicitly_created }
    end

    context "when the organisation has admin role" do
      subject(:organisation) { create(:organisation, :admin) }

      it { is_expected.not_to be_implicitly_created }
    end

    context "when the organisation has fpo:full role" do
      subject(:organisation) { create(:organisation, :fpo) }

      it { is_expected.not_to be_implicitly_created }
    end

    context "when the organisation has multiple roles including trade_tariff:full" do
      subject(:organisation) do
        create(:organisation, :fpo).tap { |o| o.assign_role!("trade_tariff:full") }
      end

      it { is_expected.not_to be_implicitly_created }
    end
  end

  describe "#available_service_roles" do
    let(:organisation) { create(:organisation) }

    context "when organisation has no service roles" do
      it "returns all service roles that are not taken" do
        expect(organisation.available_service_roles.pluck(:name)).to contain_exactly("spimm:full", "trade_tariff:full")
      end
    end

    context "when organisation has all service roles" do
      before do
        organisation.roles << organisation.available_service_roles
        organisation.save!
      end

      it "returns empty relation" do
        expect(organisation.available_service_roles).to be_empty
      end
    end
  end

  describe "#pending_request_for?" do
    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisation: organisation) }

    context "when a pending request exists for the role" do
      before do
        create(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full", status: "pending")
      end

      it "returns true" do
        expect(organisation.pending_request_for?("trade_tariff:full")).to be true
      end
    end

    context "when an approved request exists for the role" do
      before do
        create(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full", status: "approved")
      end

      it "returns false" do
        expect(organisation.pending_request_for?("trade_tariff:full")).to be false
      end
    end

    context "when no request exists for the role" do
      it "returns false" do
        expect(organisation.pending_request_for?("trade_tariff:full")).to be false
      end
    end
  end

  describe ".admin_organisation" do
    context "when an admin organisation exists" do
      let!(:admin_organisation) { create(:organisation, :admin) }

      it "returns the admin organisation" do
        expect(described_class.admin_organisation).to eq(admin_organisation)
      end
    end

    context "when no admin organisation exists" do
      it "returns nil" do
        expect(described_class.admin_organisation).to be_nil
      end
    end
  end
end
