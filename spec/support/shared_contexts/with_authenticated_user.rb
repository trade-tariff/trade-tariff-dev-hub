RSpec.shared_context "with authenticated user" do
  let(:current_user) { create(:user, organisation:) }
  let(:organisation) { create(:organisation) }
  let(:user_session) { create(:session, user: current_user) }

  let(:request_session) do
    { token: user_session.token }.merge(extra_session)
  end

  let(:extra_session) { {} }

  before do |env|
    allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: "foo"))

    if env.metadata[:type] == :request
      env = Rack::MockRequest.env_for("/")
      env.merge! app.env_config

      setter = proc { |request_env| request_env["rack.session"].merge!(request_session) }

      ActionDispatch::Session::CookieStore.new(setter, key: "_trade_tariff_dev_hub_session").call(env)
      cookies_key_value = env["action_dispatch.cookies"].as_json.first
      cookies[:id_token] = "mock-id-token"
      cookies[cookies_key_value.first] = cookies_key_value.last
    else
      session[:token] = user_session.token
    end
  end
end
