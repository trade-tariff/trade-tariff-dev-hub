RSpec.describe "Sessions", type: :request do
  include_context "with authenticated user"

  let(:organisation) { create(:organisation) }

  describe "GET /auth/redirect" do
    before do
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: decoded_id_token))
    end

    let(:decoded_id_token) do
      {
        "sub" => user_id,
        "email" => current_user.email_address,
      }
    end

    let(:user_id) { current_user.user_id }

    it "creates a Session" do
      expect { get auth_redirect_path }.to change(Session, :count).by(1)
    end

    it "redirects the user to see their api keys" do
      get auth_redirect_path
      expect(response).to redirect_to(api_keys_path)
    end

    it "sets the session", :aggregate_failures do
      get auth_redirect_path
      expect(session[:token]).to be_a_uuid
    end

    it "does not create a new user implicitly for existing user" do
      expect { get auth_redirect_path }.not_to change(User, :count)
    end

    it "does not create an organisation implicitly for existing organisation" do
      expect { get auth_redirect_path }.not_to change(Organisation, :count)
    end

    context "when the user does not exist" do
      let(:user_id) { "non-existent-user" }

      it "creates a new user" do
        expect { get auth_redirect_path }.to change(User, :count).by(1)
      end

      it "creates a new organisation" do
        expect { get auth_redirect_path }.to change(Organisation, :count).by(1)
      end
    end
  end

  describe "GET /auth/logout" do
    include_context "with authenticated user"

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
end
