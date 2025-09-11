class DecryptToken
  def initialize(token)
    @token = token
  end

  def call
    return token if Rails.env.development?

    crypt.decrypt_and_verify(token)
  end

private

  attr_reader :token

  def crypt
    @crypt ||= begin
      secret = TradeTariffDevHub.identity_encryption_secret
      key = ActiveSupport::KeyGenerator.new(secret).generate_key("salt", 32)

      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
