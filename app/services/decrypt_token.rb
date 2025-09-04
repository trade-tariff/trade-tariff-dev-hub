class DecryptToken
  def initialize(token)
    @token = token
  end

  def call
    return token if Rails.env.development?

    secret = TradeTariffDevHub.identity_encryption_secret
    key = ActiveSupport::KeyGenerator.new(secret).generate_key("salt", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end

private

  attr_reader :token
end
