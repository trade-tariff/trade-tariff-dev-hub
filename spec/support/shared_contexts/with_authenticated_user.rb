RSpec.shared_context "with authenticated user" do
  let(:current_user) { create(:user, organisation:) }
  let(:organisation) { create(:organisation) }
  let(:user_session) do
    create(
      :session,
      user: current_user,
      raw_info: {
        "bas:groupProfile" => "https://example.com/manage-team",
        "profile" => "https://example.com/update-profile",
        "exp" => (Time.zone.now + 1.hour).to_i,
        "email" => current_user.email_address,
      },
    )
  end

  let(:request_session) do
    { token: user_session.token }.merge(extra_session)
  end

  let(:extra_session) { {} }

  before do |env|
    if env.metadata[:type] == :request
      env = Rack::MockRequest.env_for("/")
      env.merge! app.env_config

      setter = proc { |request_env| request_env["rack.session"].merge!(request_session) }

      ActionDispatch::Session::CookieStore.new(setter, key: "_trade_tariff_dev_hub_session").call(env)
      cookies_key_value = env["action_dispatch.cookies"].as_json.first
      cookies[cookies_key_value.first] = cookies_key_value.last
    else
      session[:token] = user_session.token
    end
  end
end
