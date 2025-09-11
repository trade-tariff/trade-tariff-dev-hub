class VerifyToken
  def initialize(token)
    @token = token
  end

  # Verify the token and return the decoded payload if valid
  #
  # Invalid tokens return nil and log the reason.
  #
  # Possible reasons:
  # - No token provided
  # - No keys to verify against (non-development environments)
  # - Token expired
  # - Token invalid
  # - Verified user not in required group
  def call
    return log_reason(:no_token) if @token.blank?
    return log_reason(:no_keys) if identity_cognito_jwks_keys.nil? && !Rails.env.development?

    decrypted = DecryptToken.new(token).call
    decoded = DecodeJwt.new(decrypted).call
    groups = decoded&.fetch("cognito:groups", []) || []

    TradeTariffDevHub.identity_consumer.in?(groups) ? decoded : log_reason(:not_in_group)
  rescue JWT::ExpiredSignature
    log_reason(:expired)
  rescue JWT::DecodeError
    log_reason(:invalid)
  rescue StandardError => e
    log_reason(:other, e)
  end

private

  delegate :identity_cognito_jwks_keys, to: TradeTariffDevHub

  attr_reader :token

  def log_reason(reason, error = nil)
    case reason
    when :no_token
      Rails.logger.debug("No Cognito id token provided")
    when :expired
      Rails.logger.debug("Cognito id token has expired")
    when :invalid
      Rails.logger.debug("Cognito id token is invalid")
    when :no_keys
      Rails.logger.error("No JWKS keys available to verify Cognito id token")
    when :not_in_group
      Rails.logger.error("Cognito id token user not in required group")
    when :other
      Rails.logger.error("An error occurred while verifying Cognito id token: #{error.message}")
    end

    nil
  end
end
