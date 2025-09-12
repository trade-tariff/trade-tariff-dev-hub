class DecodeJwt
  def initialize(token)
    @token = token
  end

  def call
    decoded = if Rails.env.development?
                JWT.decode(token, nil, false)
              else
                config = {
                  algorithms: %w[RS256],
                  jwks: { keys: identity_cognito_jwks_keys },
                  iss: identity_cognito_issuer_url,
                  verify_iss: true,
                }
                JWT.decode(token, nil, true, config)
              end

    decoded.try(:[], 0)
  end

private

  delegate :identity_cognito_issuer_url,
           :identity_cognito_jwks_keys,
           :identity_cognito_jwks_url,
           to: TradeTariffDevHub

  attr_reader :token
end
