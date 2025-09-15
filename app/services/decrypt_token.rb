class DecryptToken
  def initialize(token)
    @token = token
  end

  def call
    return token if Rails.env.development?

    self.class.crypt.decrypt_and_verify(token)
  end

  def self.crypt
    @crypt ||= begin
      key = ActiveSupport::KeyGenerator.new(TradeTariffDevHub.identity_encryption_secret).generate_key("salt", 32)

      ActiveSupport::MessageEncryptor.new(key)
    end
  end

private

  attr_reader :token
end
