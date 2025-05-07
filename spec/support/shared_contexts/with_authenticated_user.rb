RSpec.shared_context "with authenticated user" do
  let(:status) { :authorised }
  let(:current_user) { create(:user, organisation:) }
  let(:organisation) { create(:organisation, status:) }

  let(:request_session) do
    {
      user_id: current_user.id,
      organisation_id: organisation.id,
      user_profile: {
        "bas:groupProfile" => "https://example.com/manage-team",
        "profile" => "https://example.com/update-profile",
        "exp" => (Time.zone.now + 1.hour).to_i,
        "email" => current_user.email_address,
      },
    }.merge(extra_session)
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
      session[:user_id] = current_user.id
      session[:organisation_id] = organisation.id
      session[:user_profile] = {
        "bas:groupProfile" => "https://example.com/manage-team",
        "profile" => "https://example.com/update-profile",
        "exp" => (Time.zone.now + 1.hour).to_i,
      }
    end
  end
end
