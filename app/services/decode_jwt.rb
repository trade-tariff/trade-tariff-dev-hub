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
                  jwks: { keys: jwks_keys },
                  iss: ISSUER,
                  verify_iss: true,
                }

                JWT.decode(token, nil, true, config)
              end

    decoded[0]
  end

private

  delegate :jwks_keys, to: TradeTariffDevHub

  attr_reader :token
end
