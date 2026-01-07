# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.shared_context "with authenticated user" do
  let(:current_user) { create(:user) }
  let(:user_session) { create(:session, user: current_user) }
  let(:email_address) { current_user.email_address }

  let(:decoded_id_token) do
    {
      "sub" => current_user.user_id,
      "email" => email_address,
    }
  end

  let(:verify_result) do
    VerifyToken::Result.new(valid: true, payload: decoded_id_token, reason: nil)
  end

  let(:extra_session) { { token: user_session.token } }

  before do |env|
    allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: verify_result))

    if env.metadata[:type] == :request
      env = Rack::MockRequest.env_for("/")
      env.merge! app.env_config

      setter = proc { |request_env| request_env["rack.session"].merge!(extra_session) }

      ActionDispatch::Session::CookieStore.new(setter, key: "_trade_tariff_dev_hub_session").call(env)
      cookies_key_value = env["action_dispatch.cookies"].as_json.first
      cookies[:id_token] = "mock-id-token"
      cookies[cookies_key_value.first] = cookies_key_value.last
    else
      session[:token] = user_session.token
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
