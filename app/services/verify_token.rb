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
    Rails.logger.info("[Auth] Starting token verification")
    Rails.logger.info("[Auth] Token present: #{token.present?}")
    Rails.logger.info("[Auth] Token length: #{token&.length || 0}")

    return log_reason(:no_token) if token.blank?
    return log_reason(:no_keys) unless has_keys?

    Rails.logger.info("[Auth] Decrypting token...")
    decrypted = DecryptToken.new(token).call
    Rails.logger.info("[Auth] Token decrypted, length: #{decrypted&.length || 0}")

    Rails.logger.info("[Auth] Decoding JWT...")
    decoded = DecodeJwt.new(decrypted).call

    if decoded.nil?
      Rails.logger.error("[Auth] JWT decode returned nil - check JWKS keys and token format")
      return log_reason(:decode_failed)
    end

    Rails.logger.info("[Auth] JWT decoded successfully, sub: #{decoded['sub']}")
    groups = decoded&.fetch("cognito:groups", []) || []
    Rails.logger.info("[Auth] User groups: #{groups.inspect}")
    Rails.logger.info("[Auth] Required group: #{TradeTariffDevHub.identity_consumer}")

    if TradeTariffDevHub.identity_consumer.in?(groups)
      Rails.logger.info("[Auth] Token verification successful")
      Result.new(valid: true, payload: decoded, reason: nil)
    else
      log_reason(:not_in_group, nil, groups)
    end
  rescue JWT::ExpiredSignature => e
    Rails.logger.error("[Auth] JWT expired at: #{e.message}")
    log_reason(:expired)
  rescue JWT::DecodeError => e
    Rails.logger.error("[Auth] JWT decode error: #{e.message}")
    log_reason(:invalid)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
    Rails.logger.error("[Auth] Token decryption failed - invalid message or wrong encryption key")
    Rails.logger.error("[Auth] This may indicate a mismatch between IDENTITY_ENCRYPTION_SECRET values")
    log_reason(:decryption_failed, e)
  rescue StandardError => e
    log_reason(:other, e)
  end

private

  delegate :identity_cognito_jwks_keys, to: TradeTariffDevHub

  attr_reader :token

  def log_reason(reason, error = nil, extra_context = nil)
    case reason
    when :no_token
      Rails.logger.error("[Auth] No Cognito id token provided - cookie may be missing or named differently")
    when :expired
      Rails.logger.error("[Auth] Cognito id token has expired")
    when :invalid
      Rails.logger.error("[Auth] Cognito id token is invalid - JWT structure or signature verification failed")
    when :no_keys
      Rails.logger.error("[Auth] No JWKS keys available to verify Cognito id token")
      Rails.logger.error("[Auth] JWKS URL configured: #{TradeTariffDevHub.identity_cognito_jwks_url.present?}")
    when :not_in_group
      Rails.logger.error("[Auth] Cognito id token user not in required group")
      Rails.logger.error("[Auth] Required: #{TradeTariffDevHub.identity_consumer}, User has: #{extra_context.inspect}")
    when :decode_failed
      Rails.logger.error("[Auth] JWT decode returned nil - possible JWKS key mismatch or malformed token")
    when :decryption_failed
      Rails.logger.error("[Auth] Token decryption failed: #{error&.message}")
    when :other
      Rails.logger.error("[Auth] Unexpected error verifying token: #{error.class}: #{error.message}")
      Rails.logger.error("[Auth] Backtrace: #{error.backtrace&.first(10)&.join("\n")}") if error&.backtrace
    end

    Result.new(valid: false, payload: nil, reason: reason)
  end

  def has_keys?
    return true if Rails.env.development?

    keys_present = identity_cognito_jwks_keys.present?
    Rails.logger.info("[Auth] JWKS keys available: #{keys_present}")
    keys_present
  end
end
