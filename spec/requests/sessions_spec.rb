RSpec.describe "Sessions", type: :request do
  include_context "with authenticated user"

  let(:organisation) { create(:organisation, status: :unregistered) }

  describe "GET /auth/redirect" do
    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ActionDispatch::Request).to receive(:env).and_wrap_original do |original_method, *args|
        env = original_method.call(*args)

        env["omniauth.auth"] = omniauth_auth_hash
        env
      end
      # rubocop:enable RSpec/AnyInstance
    end

    let(:omniauth_auth_hash) do
      OmniAuth::AuthHash.new(
        "extra" => {
          "raw_info" => {
            "bas:groupId" => organisation_id,
            "email" => current_user.email_address,
            "sub" => user_id,
            "exp" => 1.hour.from_now.to_i,
          },
        },
      )
    end

    let(:user_id) { current_user.user_id }
    let(:organisation_id) { current_user.organisation.organisation_id }

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
      let(:organisation_id) { "non-existent-organisation" }

      it "creates a new user" do
        expect { get auth_redirect_path }.to change(User, :count).by(1)
      end

      it "creates a new organisation" do
        expect { get auth_redirect_path }.to change(Organisation, :count).by(1)
      end
    end
  end

  describe "GET /auth/failure" do
    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ActionDispatch::Request).to receive(:env).and_wrap_original do |original_method, *args|
        env = original_method.call(*args)
        env["omniauth.error"] = omniauth_auth_hash
        env
      end
      # rubocop:enable RSpec/AnyInstance
    end

    let(:omniauth_auth_hash) do
      OmniAuth::AuthHash.new(
        "error" => "invalid_request",
        "error_description" => "The request is invalid",
        "error_reason" => "invalid_request",
        "error_uri" => "https://example.com/error",
      )
    end

    it "redirects the user to the root path" do
      get auth_failure_path

      expect(response).to redirect_to(root_path)
    end

    it "logs the error" do
      allow(Rails.logger).to receive(:error)

      get auth_failure_path

      expect(Rails.logger).to have_received(:error).with("Authentication failure: #{omniauth_auth_hash}")
    end
  end

  describe "GET /auth/destroy" do
    include_context "with authenticated user"

    it "destroys the Session" do
      expect { get logout_path }.to change(Session, :count).by(-1)
    end

    it "clears the session", :aggregate_failures do
      get logout_path
      expect(session[:token]).to be_nil
    end

    it "redirects to the provider logout path" do
      get logout_path

      expect(response).to redirect_to("/auth/openid_connect/logout")
    end
  end
end
