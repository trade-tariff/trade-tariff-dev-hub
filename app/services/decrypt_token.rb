class DecryptToken
  def initialize(token)
    @token = token
  end

  def call
    if Rails.env.development?
      Rails.logger.debug("[Auth] DecryptToken: Skipping decryption in development")
      return token
    end

    if TradeTariffDevHub.identity_encryption_secret.blank?
      Rails.logger.error("[Auth] DecryptToken: IDENTITY_ENCRYPTION_SECRET is not configured!")
      raise ArgumentError, "IDENTITY_ENCRYPTION_SECRET is required for token decryption"
    end

    Rails.logger.debug("[Auth] DecryptToken: Attempting to decrypt token")
    self.class.crypt.decrypt_and_verify(token)
  end

  def self.crypt
    @crypt ||= begin
      Rails.logger.debug("[Auth] DecryptToken: Initializing MessageEncryptor")
      key = ActiveSupport::KeyGenerator.new(TradeTariffDevHub.identity_encryption_secret).generate_key("identity_token_encryption_v1", 32)

      ActiveSupport::MessageEncryptor.new(key)
    end
  end

private

  attr_reader :token
end
