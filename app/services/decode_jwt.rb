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

  delegate :identity_cognito_jwks_keys, :identity_cognito_jwks_url, to: TradeTariffDevHub

  attr_reader :token

  def issuer
    URI(identity_cognito_jwks_url).tap { |uri|
      uri.path = "/#{uri.path.split('/').find(&:present?)}"
    }.to_s
  end
end
