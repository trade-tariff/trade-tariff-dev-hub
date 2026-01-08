class VerifyToken
  Result = Struct.new(:valid, :payload, :reason, keyword_init: true) do
    def valid?
      valid
    end

    def expired?
      reason == :expired
    end
  end

  def initialize(token)
    @token = token
  end

  # Verify the token and return a Result object.
  def call
    return log_reason(:no_token) if @token.blank?
    return log_reason(:no_keys) unless has_keys?

    decrypted = DecryptToken.new(token).call
    decoded = DecodeJwt.new(decrypted).call
    groups = decoded&.fetch("cognito:groups", []) || []

    if TradeTariffDevHub.identity_consumer.in?(groups)
      Result.new(valid: true, payload: decoded, reason: nil)
    else
      log_reason(:not_in_group)
    end
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

    Result.new(valid: false, payload: nil, reason: reason)
  end

  def has_keys?
    return true if Rails.env.development?

    identity_cognito_jwks_keys.present?
  end
end
