class DecodeJwt
  def initialize(token)
    @token = token
  end

  def call
    if token.blank?
      Rails.logger.error("[Auth] DecodeJwt: Token is blank, cannot decode")
      # Let JWT.decode raise the error for blank tokens to maintain original behavior
    end

    decoded = if Rails.env.development?
                Rails.logger.debug("[Auth] DecodeJwt: Decoding without verification (development)")
                JWT.decode(token, nil, false)
              else
                keys = identity_cognito_jwks_keys
                if keys.blank?
                  Rails.logger.error("[Auth] DecodeJwt: No JWKS keys available for verification")
                  return nil
                end

                Rails.logger.debug("[Auth] DecodeJwt: Verifying with #{keys.size} JWKS keys")
                Rails.logger.debug("[Auth] DecodeJwt: Expected issuer: #{identity_cognito_issuer_url}")

                config = {
                  algorithms: %w[RS256],
                  jwks: { keys: keys },
                  iss: identity_cognito_issuer_url,
                  verify_iss: true,
                }
                JWT.decode(token, nil, true, config)
              end

    result = decoded.try(:[], 0)
    if result
      Rails.logger.debug("[Auth] DecodeJwt: Successfully decoded JWT for sub: #{result['sub']}")
    else
      Rails.logger.error("[Auth] DecodeJwt: JWT.decode returned unexpected result: #{decoded.inspect}")
    end
    result
  rescue JWT::DecodeError => e
    Rails.logger.error("[Auth] DecodeJwt: JWT decode error: #{e.class}: #{e.message}")
    raise
  end

private

  delegate :identity_cognito_issuer_url,
           :identity_cognito_jwks_keys,
           :identity_cognito_jwks_url,
           to: TradeTariffDevHub

  attr_reader :token
end
