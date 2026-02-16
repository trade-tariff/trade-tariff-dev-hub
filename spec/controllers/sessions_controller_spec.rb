RSpec.describe SessionsController, type: :controller do
  describe "GET #destroy" do
    let(:token) { SecureRandom.uuid }
    let!(:user_session) { create(:session, token: token) }

    before do
      session[:token] = token
    end

    it "clears the stored session", :aggregate_failures do
      get :destroy

      expect(response).to redirect_to(root_path)
      expect(Session.exists?(id: user_session.id)).to be(false)
      expect(session[:token]).to be_nil
    end
  end

  describe "GET #handle_redirect" do
    let(:token_payload) do
      {
        "sub" => "user-123",
        "email" => "user@example.com",
        "name" => "User Example",
        "exp" => 1.hour.from_now.to_i,
      }
    end
    let(:valid_result) { VerifyToken::Result.new(valid: true, payload: token_payload, reason: nil) }

    before do
      allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: valid_result))
    end

    context "when the user exists already" do
      let!(:user) { create(:user, email_address: "user@example.com") }

      before do
        cookies[TradeTariffDevHub.id_token_cookie_name] = "encoded-token"
      end

      it "creates a session and signs the user in", :aggregate_failures do
        expect { get :handle_redirect }.to change(Session, :count)
        expect(response).to redirect_to(organisation_path(user.organisation))
        expect(Session.last.user.email_address).to eq("user@example.com")
        expect(Session.last.raw_info).to eq(token_payload)
        expect(Session.last.id_token).to eq("encoded-token")
      end

      it "stores a hashed session token" do
        get :handle_redirect

        plain_token = session[:token]

        expect(Session.last.token).to eq(Session.digest(plain_token))
      end

      it "redirects and clears cookies when token is invalid", :aggregate_failures do
        invalid_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :invalid)
        allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: invalid_result))
        allow(TradeTariffDevHub).to receive_messages(identity_consumer_url: "http://identity.example.com/admin",
                                                     identity_cookie_domain: ".example.com")
        cookies[TradeTariffDevHub.refresh_token_cookie_name] = "refresh-token"
        get :handle_redirect
        expect(response).to redirect_to("http://identity.example.com/admin")
        # NOTE: These are positive instructions to delete the cookies and not the current cookie values. Refresh token is not deleted here since we'll reuse it for reauthentication.
        expect(response.cookies).to eq(TradeTariffDevHub.id_token_cookie_name.to_s => nil)
      end

      it "redirects without clearing cookies when token is expired", :aggregate_failures do
        expired_result = VerifyToken::Result.new(valid: false, payload: nil, reason: :expired)
        allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: expired_result))
        allow(TradeTariffDevHub).to receive(:identity_consumer_url).and_return("http://identity.example.com/admin")
        cookies[TradeTariffDevHub.refresh_token_cookie_name] = "refresh-token"
        get :handle_redirect
        expect(response).to redirect_to("http://identity.example.com/admin")
        expect(cookies[TradeTariffDevHub.id_token_cookie_name]).to eq("encoded-token")
        expect(cookies[TradeTariffDevHub.refresh_token_cookie_name]).to eq("refresh-token")
      end
    end

    context "when the user does not exist" do
      it "redirects to landing page with access denied message and clears cookies", :aggregate_failures do
        allow(TradeTariffDevHub).to receive_messages(identity_consumer_url: "http://identity.example.com/admin",
                                                     identity_cookie_domain: ".example.com")
        cookies[TradeTariffDevHub.id_token_cookie_name] = "encoded-token"
        cookies[TradeTariffDevHub.refresh_token_cookie_name] = "refresh-token"
        expect { get :handle_redirect }.not_to change(User, :count)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("You need an invitation from an existing organisation to access it")

        # NOTE: These are positive instructions to delete the cookies and not the current cookie values. Refresh token is not deleted here since we'll reuse it for reauthentication.
        expect(response.cookies).to eq(TradeTariffDevHub.id_token_cookie_name.to_s => nil)
      end
    end
  end
end
