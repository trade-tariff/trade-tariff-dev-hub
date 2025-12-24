RSpec.describe RoleRequest, type: :model do
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }

  describe "#approve!" do
    let(:organisation) { create(:organisation) }
    let(:role_request) { create(:role_request, organisation: organisation, role_name: "fpo:full") }

    it "updates status to approved" do
      expect { role_request.approve! }.to change { role_request.reload.status }.from("pending").to("approved")
    end

    it "assigns the role to the organisation" do
      expect { role_request.approve! }.to change { organisation.reload.has_role?("fpo:full") }.from(false).to(true)
    end

    it "returns self" do
      expect(role_request.approve!).to eq(role_request)
    end

    context "when role assignment fails" do
      before do
        allow(organisation).to receive(:assign_role!).and_raise(ActiveRecord::RecordInvalid.new(Role.new))
      end

      it "raises an error" do
        expect { role_request.approve! }.to raise_error(ActiveRecord::RecordInvalid)
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
end
