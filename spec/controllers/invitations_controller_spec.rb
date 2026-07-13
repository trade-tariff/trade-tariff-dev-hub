# frozen_string_literal: true

RSpec.describe InvitationsController, type: :controller do
  include_context "with authenticated user"

  let(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user) }

  describe "missing invitation guards" do
    before { allow(controller).to receive(:set_invitation) }

    {
      edit: :get,
      update: :get,
      resend: :get,
      delete: :delete,
    }.each do |action, request_method|
      it "redirects from #{action}" do
        public_send(request_method, action, params: { id: "missing" })

        expect(response).to redirect_to(organisation_path(current_user.organisation))
      end
    end
  end

  describe "GET #update (delete route)" do
    it "redirects for a pending invitation", :aggregate_failures do
      allow(controller.request).to receive(:path).and_return("/invitations/#{invitation.id}/delete")

      get :update, params: { id: invitation.id }

      expect(flash[:alert]).to eq("Invalid invitation state.")
      expect(response).to redirect_to(organisation_path(current_user.organisation))
    end

    it "rejects an invitation in an invalid state" do
      invitation.accepted!

      get :update, params: { id: invitation.id }

      expect(flash[:alert]).to eq("Invalid invitation state.")
    end
  end

  describe "PATCH #update" do
    it "rejects an invitation that is not pending" do
      invitation.revoked!

      patch :update, params: { id: invitation.id }

      expect(flash[:alert]).to eq("Only pending invitations can be revoked.")
    end
  end

  describe "GET #resend" do
    it "rejects an invitation that is not pending" do
      invitation.revoked!

      get :resend, params: { id: invitation.id }

      expect(flash[:alert]).to eq("Only pending invitations can be resent.")
    end
  end

  describe "invitation lookup" do
    it "sets an alert when lookup raises an error" do
      allow(controller).to receive(:find_owned_record).and_raise(StandardError, "Lookup failed")

      get :edit, params: { id: invitation.id }

      expect(flash[:alert]).to eq("Invitation not found.")
    end
  end
end
