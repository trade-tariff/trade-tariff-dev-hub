if ENV.fetch("SCP_ENABLED", "false") == "true"
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :openid_connect,
             name: :openid_connect,
             scope: %i[openid profile],
             response_type: :code,
             issuer: ENV['SCP_OPEN_ID_ISSUER_BASE_URL'],
             discovery: true,
             callback_path: ENV['SCP_OPEN_ID_CALLBACK_PATH'],
             client_options: {
               identifier: ENV['SCP_OPEN_ID_CLIENT_ID'],
               secret: ENV['SCP_OPEN_ID_CLIENT_SECRET'],
               redirect_uri: "#{ENV['SCP_OPEN_ID_BASE_URL']}#{ENV['SCP_OPEN_ID_CALLBACK_PATH']}",
               host: URI.parse(ENV['SCP_OPEN_ID_ISSUER_BASE_URL']).host,
               scheme: 'https',
               port: 443,
               authorization_params: { audience: ENV['SCP_OPEN_ID_BASE_URL'] }
             }

  end

  OmniAuth.config.logger = Rails.logger

  OmniAuth.config.on_failure = proc do |env|
    error = env['omniauth.error'] || 'Unknown error'
    Rails.logger.error("OmniAuth failure: #{error.inspect}")
    env['rack.session']['omniauth.error'] = error.to_s
    SessionsController.action(:failure).call(env)
  end

  # TODO: We redirect to a hosted provider to login which requires a GET request
  #       find a way of making the login request via a POST
  OmniAuth.config.silence_get_warning = true
  OmniAuth.config.allowed_request_methods = [:get, :post]
end
