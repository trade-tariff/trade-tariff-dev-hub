class DecryptSecret
  def call(encrypted)
    encoded_iv, encoded_encrypted = encrypted.split(":")
    iv = Base64.decode64(encoded_iv)
    encrypted_data = Base64.decode64(encoded_encrypted)
    tag = encrypted_data[-16..]
    ciphertext = encrypted_data[0...-16]
    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.decrypt
    cipher.key = crypto_key
    cipher.iv = iv
    cipher.auth_tag = tag
    cipher.auth_data = ""
    cipher.update(ciphertext) + cipher.final # rubocop:disable Rails/SaveBang
  rescue StandardError => e
    Rails.logger.warn "Failed to decrypt data: #{e.message}. Possibly an unencrypted value?"
    encrypted
  end

  delegate :crypto_key, to: :class

  def self.crypto_key
    @crypto_key ||= begin
      base64_key = ENV.fetch("ENCRYPTION_KEY", "")
      Base64.decode64(base64_key)
    end
  end
end
