# frozen_string_literal: true

Rails.application.config.after_initialize do
  next if Rails.env.test?

  if TradeTariffDevHub.identity_cognito_jwks_url.blank?
    Rails.logger.warn("[Auth Config] WARNING: IDENTITY_COGNITO_JWKS_URL is not set - token verification will fail!")
  end

  if TradeTariffDevHub.identity_encryption_secret.blank? && !Rails.env.development?
    Rails.logger.warn("[Auth Config] WARNING: IDENTITY_ENCRYPTION_SECRET is not set - token decryption will fail!")
  end
end
