RSpec.describe "Invitations", type: :request do
  include_context "with authenticated user"

  describe "GET /invitations/new" do
    it "renders the new invitation form", :aggregate_failures do
      get new_invitation_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Enter the email address")
    end

    it "includes the correct action URL", :aggregate_failures do
      get new_invitation_path
      expect(response.body).to include('action="/invitations"')
      expect(response.body).to include('method="post"')
    end

    context "when the organisation user is an admin" do
      let(:current_user) { create(:user, organisation: create(:organisation, :admin)) }

      it "renders the new invitation form", :aggregate_failures do
        get new_invitation_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Enter the email address")
      end

      it "includes the correct action URL", :aggregate_failures do
        get new_invitation_path
        expect(response.body).to include('action="/invitations"')
        expect(response.body).to include('method="post"')
      end
    end
  end

  describe "POST /invitations" do
    context "with valid parameters" do
      let(:params) { { invitation: { invitee_email: "foo@bar.com" } } }

      before do
        stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
          .to_return(
            status: 202,
            body: '{"data":{"id": "beff2bec-b82a-4196-b393-d733394a4ec0","type":"notification"}}',
            headers: { "Content-Type" => "application/json" },
          )

        allow(SendNotification).to receive(:new).and_call_original
      end

      it "creates a new invitation" do
        expect { post invitations_path, params: }
          .to change { Invitation.where(invitee_email: "foo@bar.com").count }.by(1)
      end

      it "redirects to the organisation page with a success notice", :aggregate_failures do
        post invitations_path, params: params
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Invitation sent to foo@bar.com")
      end

      it "sends an invitation email" do
        post invitations_path, params: params
        expect(SendNotification).to have_received(:new).with(instance_of(Notification))
      end
    end

    context "with invalid parameters" do
      let(:params) { { invitation: { invitee_email: "invalid-email" } } }

      it "does not create a new invitation" do
        expect { post invitations_path, params: }
          .not_to change(Invitation, :count)
      end

      it "re-renders the new template with errors", :aggregate_failures do
        post invitations_path, params: params
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Enter a properly formatted email address")
      end
    end
  end

  describe "GET /invitations/:id/revoke" do
    let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user) }

    it "renders the revoke confirmation page", :aggregate_failures do
      get edit_invitation_path(invitation)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your invitation will be revoked")
    end
  end

  describe "PATCH /invitations/:id" do
    let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user) }

    it "revokes the invitation and redirects with a success notice", :aggregate_failures do
      patch invitation_path(invitation)
      expect(response).to redirect_to(organisation_path(current_user.organisation))
      follow_redirect!
      expect(response.body).to include("Invitation to #{invitation.invitee_email} has been revoked.")
      expect(invitation.reload.status).to eq("revoked")
    end

    it "does not delete the invitation record" do
      expect { patch invitation_path(invitation) }
        .not_to change(Invitation, :count)
    end

    context "when an error occurs" do
      before do
        allow(Invitation).to receive(:find_by).and_raise(StandardError, "Some error")
      end

      it "redirects with an alert message", :aggregate_failures do
        patch invitation_path(invitation)
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("There was a problem revoking the invitation")
      end
    end
  end

  describe "GET /invitations/:id/resend" do
    let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user, status: "revoked") }

    before do
      stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
        .to_return(
          status: 202,
          body: '{"data":{"id": "beff2bec-b82a-4196-b393-d733394a4ec0","type":"notification"}}',
          headers: { "Content-Type" => "application/json" },
        )

      allow(SendNotification).to receive(:new).and_call_original
    end

    it "resends the invitation and redirects with a success notice", :aggregate_failures do
      get resend_invitation_path(invitation)
      expect(response).to redirect_to(organisation_path(current_user.organisation))
      follow_redirect!
      expect(response.body).to include("Invitation resent to #{invitation.invitee_email}")
      expect(invitation.reload.status).to eq("pending")
    end

    it "sends an invitation email" do
      get resend_invitation_path(invitation)
      expect(SendNotification).to have_received(:new).with(instance_of(Notification))
    end
  end
end
