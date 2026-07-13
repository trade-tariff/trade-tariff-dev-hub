# frozen_string_literal: true

RSpec.describe Admin::OrganisationRolesController, type: :controller do
  include_context "with authenticated user"

  before do
    current_user.organisation.assign_role!("admin")
  end

  describe "POST #create" do
    let(:organisation) { create(:organisation, :without_roles) }

    it "assigns the role" do
      post :create, params: { organisation_id: organisation.id, role_name: "trade_tariff:full" }

      expect(organisation.reload.has_role?("trade_tariff:full")).to be(true)
    end

    it "sets an alert when assignment fails" do
      allow(Organisation).to receive(:find).and_return(organisation)
      allow(organisation).to receive(:assign_role!).and_raise(ActiveRecord::RecordInvalid, organisation)

      post :create, params: { organisation_id: organisation.id, role_name: "trade_tariff:full" }

      expect(flash[:alert]).to be_present
    end

    it "rejects an invalid role" do
      post :create, params: { organisation_id: organisation.id, role_name: "admin" }

      expect(flash[:alert]).to eq("Invalid role")
    end
  end

  describe "DELETE #destroy" do
    it "removes the role" do
      organisation = create(:organisation, :trade_tariff_only)

      delete :destroy, params: { organisation_id: organisation.id, role_name: "trade_tariff:full" }

      expect(organisation.reload.has_role?("trade_tariff:full")).to be(false)
    end

    it "keeps the Trade Tariff role while active keys exist" do
      organisation = create(:organisation, :trade_tariff_only)
      create(:trade_tariff_key, organisation: organisation)

      delete :destroy, params: { organisation_id: organisation.id, role_name: "trade_tariff:full" }

      expect(flash[:alert]).to eq("Cannot remove role while organisation has Trade Tariff keys")
    end

    it "keeps the FPO role while active API keys exist" do
      organisation = create(:organisation)
      create(:api_key, organisation: organisation)

      delete :destroy, params: { organisation_id: organisation.id, role_name: "fpo:full" }

      expect(flash[:alert]).to eq("Cannot remove role while organisation has active FPO API keys")
    end

    it "sets an alert when removal fails" do
      organisation = create(:organisation, :trade_tariff_only)
      allow(Organisation).to receive(:find).and_return(organisation)
      allow(organisation).to receive(:unassign_role!).and_raise(ActiveRecord::RecordNotFound, "Role not found")

      delete :destroy, params: { organisation_id: organisation.id, role_name: "trade_tariff:full" }

      expect(flash[:alert]).to eq("Role not found")
    end
  end

  describe "#removal_block_message" do
    it "returns messages for otherwise unreachable block reasons", :aggregate_failures do
      organisation = instance_double(Organisation)
      controller.instance_variable_set(:@organisation, organisation)
      allow(organisation).to receive(:remove_role_block_reason).and_return(:admin_role, nil)

      expect(controller.send(:removal_block_message, "admin")).to eq("Cannot remove admin role")
      expect(controller.send(:removal_block_message, "unknown")).to eq("Cannot remove role")
    end
  end
end
