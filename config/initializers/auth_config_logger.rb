# frozen_string_literal: true

# Log authentication configuration at startup for debugging
Rails.application.config.after_initialize do
  next if Rails.env.test?

  Rails.logger.info("[Auth Config] ========================================")
  Rails.logger.info("[Auth Config] Authentication Configuration at Startup")
  Rails.logger.info("[Auth Config] ========================================")
  Rails.logger.info("[Auth Config] Identity authentication enabled: #{TradeTariffDevHub.identity_authentication_enabled?}")
  Rails.logger.info("[Auth Config] Environment: #{TradeTariffDevHub.environment}")
  Rails.logger.info("[Auth Config] id_token cookie name: #{TradeTariffDevHub.id_token_cookie_name}")
  Rails.logger.info("[Auth Config] refresh_token cookie name: #{TradeTariffDevHub.refresh_token_cookie_name}")
  Rails.logger.info("[Auth Config] Cookie domain: #{TradeTariffDevHub.identity_cookie_domain}")
  Rails.logger.info("[Auth Config] Identity base URL: #{TradeTariffDevHub.identity_base_url}")
  Rails.logger.info("[Auth Config] Identity consumer: #{TradeTariffDevHub.identity_consumer}")
  Rails.logger.info("[Auth Config] Identity consumer URL: #{TradeTariffDevHub.identity_consumer_url}")
  Rails.logger.info("[Auth Config] JWKS URL configured: #{TradeTariffDevHub.identity_cognito_jwks_url.present?}")
  Rails.logger.info("[Auth Config] Encryption secret configured: #{TradeTariffDevHub.identity_encryption_secret.present?}")

  # Warn about potential misconfigurations
  if TradeTariffDevHub.identity_authentication_enabled?
    if TradeTariffDevHub.identity_cognito_jwks_url.blank?
      Rails.logger.warn("[Auth Config] WARNING: IDENTITY_COGNITO_JWKS_URL is not set - token verification will fail!")
    end

    if TradeTariffDevHub.identity_encryption_secret.blank? && !Rails.env.development?
      Rails.logger.warn("[Auth Config] WARNING: IDENTITY_ENCRYPTION_SECRET is not set - token decryption will fail!")
    end
  end

  Rails.logger.info("[Auth Config] ========================================")
end
