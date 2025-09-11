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
                  iss: issuer,
                  verify_iss: true,
                }

                JWT.decode(token, nil, true, config)
              end

    decoded[0]
  end

private

  delegate :identity_cognito_jwks_keys, to: TradeTariffDevHub

  attr_reader :token

  def issuer
    uri = URI(identity_cognito_jwks_keys)
    pool_id = uri.path.split("/").first
    "#{uri.host}/#{pool_id}"
  end
end
