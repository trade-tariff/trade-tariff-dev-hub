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

    context "when inviting admin domain email to non-admin organisation" do
      let(:admin_domain) { TradeTariffDevHub.admin_domain }
      let(:params) { { invitation: { invitee_email: "user@#{admin_domain}" } } }

      it "does not create a new invitation", :aggregate_failures do
        expect { post invitations_path, params: params }
          .not_to change(Invitation, :count)
      end

      it "re-renders the new template with admin domain error", :aggregate_failures do
        post invitations_path, params: params
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("#{admin_domain} email addresses can only be invited to admin organisations")
        expect(response.body).not_to include("<%= ENV.fetch")
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

    context "when an error occurs during revocation" do
      before do
        # Stub update! to raise an error when revoked! is called (which calls update! internally)
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Invitation).to receive(:update!).and_raise(StandardError, "Some error")
        # rubocop:enable RSpec/AnyInstance
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
    let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user, status: "pending") }

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

  describe "GET /invitations/:id/delete" do
    context "when invitation is revoked" do
      let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user, status: "revoked") }

      it "renders the delete confirmation page", :aggregate_failures do
        get delete_invitation_path(invitation)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Delete invitation")
        expect(response.body).to include("This invitation will be deleted with immediate effect")
        expect(response.body).to include(invitation.invitee_email)
      end

      it "displays invitation details in a table", :aggregate_failures do
        get delete_invitation_path(invitation)
        expect(response.body).to include("Invitee email")
        expect(response.body).to include(invitation.invitee_email)
        expect(response.body).to include("Created on")
        expect(response.body).to include("Status")
      end
    end

    context "when invitation is not revoked" do
      let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user, status: "pending") }

      it "redirects with an alert", :aggregate_failures do
        get delete_invitation_path(invitation)
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Invalid invitation state")
      end
    end

    context "when user is an admin accessing another organisation's invitation" do
      let(:admin_organisation) { create(:organisation, :admin) }
      let(:current_user) { create(:user, organisation: admin_organisation) }
      let(:other_organisation) { create(:organisation) }
      let!(:invitation) do
        user = create(:user, organisation: other_organisation)
        create(:invitation, organisation: other_organisation, user: user, status: "revoked")
      end

      it "allows admin to access the delete confirmation page", :aggregate_failures do
        get delete_invitation_path(invitation)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Delete invitation")
      end
    end

    context "when user tries to access another organisation's invitation" do
      let(:other_organisation) { create(:organisation) }
      let!(:invitation) do
        user = create(:user, organisation: other_organisation)
        create(:invitation, organisation: other_organisation, user: user, status: "revoked")
      end

      it "redirects with an alert", :aggregate_failures do
        get delete_invitation_path(invitation)
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Invitation not found")
      end
    end
  end

  describe "DELETE /invitations/:id/delete" do
    context "when invitation is revoked" do
      let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user, status: "revoked") }

      it "deletes the invitation and redirects with a success notice", :aggregate_failures do
        expect { delete delete_invitation_path(invitation) }
          .to change(Invitation, :count).by(-1)

        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Invitation for #{invitation.invitee_email} has been deleted.")
      end
    end

    context "when invitation is not revoked" do
      let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user, status: "pending") }

      it "does not delete the invitation and redirects with an alert", :aggregate_failures do
        expect { delete delete_invitation_path(invitation) }
          .not_to(change(Invitation, :count))

        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Only revoked invitations can be deleted")
      end
    end

    context "when invitation does not exist" do
      it "redirects with an alert", :aggregate_failures do
        delete delete_invitation_path("non-existent-id")
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Invitation not found")
      end
    end

    context "when user is an admin deleting another organisation's invitation" do
      let(:admin_organisation) { create(:organisation, :admin) }
      let(:current_user) { create(:user, organisation: admin_organisation) }
      let(:other_organisation) { create(:organisation) }
      let!(:invitation) do
        user = create(:user, organisation: other_organisation)
        create(:invitation, organisation: other_organisation, user: user, status: "revoked")
      end

      it "deletes the invitation and redirects to admin organisation page", :aggregate_failures do
        expect { delete delete_invitation_path(invitation) }
          .to change(Invitation, :count).by(-1)

        expect(response).to redirect_to(admin_organisation_path(other_organisation.id))
        follow_redirect!
        expect(response.body).to include("Invitation for #{invitation.invitee_email} has been deleted.")
      end
    end
  end

  describe "PATCH /invitations/:id redirect logic" do
    context "when user is an admin revoking another organisation's invitation" do
      let(:admin_organisation) { create(:organisation, :admin) }
      let(:current_user) { create(:user, organisation: admin_organisation) }
      let(:other_organisation) { create(:organisation) }
      let!(:invitation) do
        user = create(:user, organisation: other_organisation)
        create(:invitation, organisation: other_organisation, user: user, status: "pending")
      end

      it "redirects to admin organisation page", :aggregate_failures do
        patch invitation_path(invitation)
        expect(response).to redirect_to(admin_organisation_path(other_organisation.id))
        follow_redirect!
        expect(response.body).to include("Invitation to #{invitation.invitee_email} has been revoked.")
      end
    end

    context "when user is not an admin revoking their own invitation" do
      let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user) }

      it "redirects to own organisation page", :aggregate_failures do
        patch invitation_path(invitation)
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Invitation to #{invitation.invitee_email} has been revoked.")
      end
    end
  end

  describe "GET /invitations/:id/resend redirect logic" do
    context "when user is an admin resending another organisation's invitation" do
      let(:admin_organisation) { create(:organisation, :admin) }
      let(:current_user) { create(:user, organisation: admin_organisation) }
      let(:other_organisation) { create(:organisation) }
      let!(:invitation) do
        user = create(:user, organisation: other_organisation)
        create(:invitation, organisation: other_organisation, user: user, status: "pending")
      end

      before do
        stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
          .to_return(
            status: 202,
            body: '{"data":{"id": "beff2bec-b82a-4196-b393-d733394a4ec0","type":"notification"}}',
            headers: { "Content-Type" => "application/json" },
          )

        allow(SendNotification).to receive(:new).and_call_original
      end

      it "redirects to admin organisation page", :aggregate_failures do
        get resend_invitation_path(invitation)
        expect(response).to redirect_to(admin_organisation_path(other_organisation.id))
        follow_redirect!
        expect(response.body).to include("Invitation resent to #{invitation.invitee_email}")
      end
    end

    context "when user is not an admin resending their own invitation" do
      let!(:invitation) { create(:invitation, organisation: current_user.organisation, user: current_user) }

      before do
        stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
          .to_return(
            status: 202,
            body: '{"data":{"id": "beff2bec-b82a-4196-b393-d733394a4ec0","type":"notification"}}',
            headers: { "Content-Type" => "application/json" },
          )

        allow(SendNotification).to receive(:new).and_call_original
      end

      it "redirects to own organisation page" do
        get resend_invitation_path(invitation)
        expect(response).to redirect_to(organisation_path(current_user.organisation))
      end
    end
  end
end
