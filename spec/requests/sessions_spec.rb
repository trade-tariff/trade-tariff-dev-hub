RSpec.describe "Sessions", type: :request do
  include_context "with authenticated user"

  describe "GET /auth/redirect" do
    let(:extra_session) { {} }

    context "when state parameter is not provided" do
      it "redirects to the root path", :aggregate_failures do
        get auth_redirect_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Authentication failed. Please try again.")
      end
    end

    context "when state parameter is provided" do
      let(:extra_session) { { state: "abcdef0123456789" } }
      let(:params) { { state: "abcdef0123456789" } }

      it "redirects the user to their organisation page" do
        get auth_redirect_path, params: params
        expect(response).to redirect_to(organisation_path(current_user.organisation))
      end

      it "creates a Session" do
        expect { get auth_redirect_path, params: params }.to change(Session, :count).by(1)
      end

      it "redirects the user to see their api keys" do
        get auth_redirect_path, params: params
        expect(response).to redirect_to(api_keys_path)
      end

      it "sets the session token" do
        get auth_redirect_path, params: params
        expect(session[:token]).to be_a_uuid
      end

      it "does not create a new user implicitly for existing user" do
        expect { get auth_redirect_path }.not_to change(User, :count)
      end

      it "does not create an organisation implicitly for existing organisation" do
        expect { get auth_redirect_path }.not_to change(Organisation, :count)
      end
    end

    context "when the user does not exist and has no invitation" do
      let(:extra_session) { { state: "abcdef0123456789" } }
      let(:params) { { state: "abcdef0123456789" } }
      let(:email_address) { "non-existing@bar.com" }

      it "does not create a new user" do
        expect { get auth_redirect_path }.not_to change(User, :count)
      end

      it "redirects to root with private beta message", :aggregate_failures do
        get auth_redirect_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("private beta")
      end
    end

    context "when the user does not exist but has a pending invitation" do
      let(:email_address) { "invited@example.com" }
      let(:inviting_user) { create(:user) }

      before do
        create(
          :invitation,
          invitee_email: email_address,
          organisation: inviting_user.organisation,
          status: :pending,
          user: inviting_user,
        )
      end

      it "creates a new user" do
        expect { get auth_redirect_path }.to change(User, :count).by(1)
      end

      it "does not create a new organisation" do
        expect { get auth_redirect_path }.not_to change(Organisation, :count)
      end

      it "accepts the invitation" do
        expect { get auth_redirect_path }.to change { Invitation.accepted.count }.by(1)
      end
    end

    context "when the session token is already set" do
      let(:extra_session) { { state: "abcdef0123456789", token: "existing-token" } }
      let(:params) { { state: "abcdef0123456789" } }

      before do
        create(:session, token: "existing-token", user: current_user)
      end

      it "does not create a new Session" do
        expect { get auth_redirect_path }.not_to change(Session, :count)
      end
    end
  end

  describe "GET /auth/logout" do
    it "destroys the Session" do
      expect { get logout_path }.to change(Session, :count).by(-1)
    end

    it "clears the session" do
      get logout_path
      expect(session[:token]).to be_nil
    end

    it "redirects to the root path" do
      get logout_path

      expect(response).to redirect_to(root_path)
    end

    it "deletes the id_token cookie" do
      cookies[:id_token] = "some-id-token"
      expect { get logout_path }.to change { cookies[:id_token] }.from("some-id-token").to("")
    end

    it "deletes the refresh_token cookie" do
      cookies[:refresh_token] = "some-refresh-token"
      expect { get logout_path }.to change { cookies[:refresh_token] }.from("some-refresh-token").to("")
    end
  end

  describe "GET /auth/invalid" do
    it "redirects to the root path", :aggregate_failures do
      get auth_invalid_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Authentication failed. Please try again.")
    end
  end
end
