# frozen_string_literal: true

RSpec.describe "Homepage", type: :request do
  describe "GET /" do
    context "when user has no session" do
      it "returns http success", :aggregate_failures do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Start now")
      end
    end

    context "when user has a valid identity session" do
      include_context "with authenticated user"

      it "redirects to the organisation page" do
        get root_path
        expect(response).to redirect_to(organisation_path(current_user.organisation))
      end
    end

    context "when user has a stale identity session" do
      let(:current_user) { create(:user) }
      let(:plain_token) { SecureRandom.uuid }
      let(:id_token_value) { "stale-id-token" }
      let(:invalid_verify_result) { VerifyToken::Result.new(valid: false, payload: nil, reason: "expired") }

      before do
        user_session = create(:session, user: current_user, token: plain_token, id_token: id_token_value)
        allow(VerifyToken).to receive(:new).with(id_token_value).and_return(
          instance_double(VerifyToken, call: invalid_verify_result),
        )

        env = Rack::MockRequest.env_for("/")
        env.merge! app.env_config
        setter = proc { |request_env| request_env["rack.session"].merge!(token: plain_token) }
        ActionDispatch::Session::CookieStore.new(setter, key: "_trade_tariff_dev_hub_session").call(env)
        cookies_key_value = env["action_dispatch.cookies"].as_json.first
        cookies[TradeTariffDevHub.id_token_cookie_name] = user_session.id_token
        cookies[cookies_key_value.first] = cookies_key_value.last
      end

      it "returns http success and clears the session", :aggregate_failures do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Start now")
        expect(Session.find_by_token(plain_token)).to be_nil
      end
    end
  end
end
