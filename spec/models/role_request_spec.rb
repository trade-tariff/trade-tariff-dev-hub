RSpec.describe RoleRequest, type: :model do
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe "#approve!" do
    let(:admin_organisation) { create(:organisation, :admin) }
    let(:admin_user) { create(:user, organisation: admin_organisation) }
    let(:organisation) { create(:organisation) }
    let(:role_request) { create(:role_request, organisation: organisation, role_name: "trade_tariff:full") }

    it "updates status to approved" do
      expect { role_request.approve!(approved_by: admin_user) }.to change { role_request.reload.status }.from("pending").to("approved")
    end

    it "assigns the role to the organisation" do
      expect { role_request.approve!(approved_by: admin_user) }.to change { organisation.reload.has_role?("trade_tariff:full") }.from(false).to(true)
    end

    it "returns self" do
      expect(role_request.approve!(approved_by: admin_user)).to eq(role_request)
    end

    context "when approved_by is nil" do
      it "raises an ArgumentError" do
        expect { role_request.approve!(approved_by: nil) }.to raise_error(ArgumentError, "approve! must be called by an admin user")
      end
    end

    context "when approved_by is not an admin" do
      let(:non_admin_user) { create(:user, organisation: organisation) }

      it "raises an ArgumentError" do
        expect { role_request.approve!(approved_by: non_admin_user) }.to raise_error(ArgumentError, "approve! must be called by an admin user")
      end
    end

    context "when role assignment fails" do
      before do
        allow(organisation).to receive(:assign_role!).and_raise(ActiveRecord::RecordInvalid.new(Role.new))
      end

      it "raises an error" do
        expect { role_request.approve!(approved_by: admin_user) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe ".pending" do
    let!(:pending_request) { create(:role_request, status: "pending") }

    before do
      create(:role_request, status: "approved")
      create(:role_request, status: "rejected")
    end

    it "returns only pending requests" do
      expect(described_class.pending).to contain_exactly(pending_request)
    end
  end

  describe "validations" do
    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisation: organisation) }

    describe "#note" do
      it "requires a note to be present", :aggregate_failures do
        role_request = build(:role_request, organisation: organisation, user: user, note: nil)

        expect(role_request).not_to be_valid
        expect(role_request.errors[:note]).to include("You must provide information about why you need access to this role")
      end

      it "requires a note to not be blank", :aggregate_failures do
        role_request = build(:role_request, organisation: organisation, user: user, note: "")

        expect(role_request).not_to be_valid
        expect(role_request.errors[:note]).to include("You must provide information about why you need access to this role")
      end

      it "allows a role request with a note" do
        role_request = build(:role_request, organisation: organisation, user: user, note: "I need this access")

        expect(role_request).to be_valid
      end
    end
  end

  describe "#organisation_does_not_have_role" do
    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisation: organisation) }

    context "when organisation already has the role" do
      before do
        organisation.assign_role!("trade_tariff:full")
      end

      it "prevents creating a role request", :aggregate_failures do
        role_request = build(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full")

        expect(role_request).not_to be_valid
        expect(role_request.errors[:role_name]).to include("is already assigned to this organisation")
      end
    end

    context "when organisation does not have the role" do
      it "allows creating a role request" do
        role_request = build(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full")

        expect(role_request).to be_valid
      end
    end
  end

  describe "#no_duplicate_pending_request" do
    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisation: organisation) }

    context "when there is already a pending request for the same role and organisation" do
      before do
        create(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full", status: "pending")
      end

      it "prevents creating a duplicate pending request", :aggregate_failures do
        duplicate_request = build(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full")

        expect(duplicate_request).not_to be_valid
        expect(duplicate_request.errors[:role_name]).to include("has already been requested and is pending")
      end
    end

    context "when there is an approved request for the same role and organisation" do
      before do
        create(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full", status: "approved")
      end

      it "allows creating a new request" do
        new_request = build(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full")

        expect(new_request).to be_valid
      end
    end

    context "when there is a rejected request for the same role and organisation" do
      before do
        create(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full", status: "rejected")
      end

      it "allows creating a new request" do
        new_request = build(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full")

        expect(new_request).to be_valid
      end
    end

    context "when there is a pending request for a different role" do
      before do
        create(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full", status: "pending")
      end

      it "does not allow creating another request" do
        new_request = build(:role_request, organisation: organisation, user: user, role_name: "fpo:full")

        expect(new_request).not_to be_valid
      end
    end

    context "when there is a pending request for the same role but different organisation" do
      let(:other_organisation) { create(:organisation) }

      before do
        create(:role_request, organisation: other_organisation, role_name: "trade_tariff:full", status: "pending")
      end

      it "allows creating a request for the same role" do
        new_request = build(:role_request, organisation: organisation, user: user, role_name: "trade_tariff:full")

        expect(new_request).to be_valid
      end
    end
  end
end
