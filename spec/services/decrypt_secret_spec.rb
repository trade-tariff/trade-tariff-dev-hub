RSpec.describe DecryptSecret do
  subject(:call) { described_class.new.call(encrypted) }

  let(:encrypted) do
    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.encrypt
    cipher.key = Base64.decode64(ENV.fetch("ENCRYPTION_KEY"))
    cipher.auth_data = ""
    iv = cipher.random_iv
    encrypted_data = cipher.update("my_secret") + cipher.final
    tag = cipher.auth_tag

    "#{Base64.strict_encode64(iv)}:#{Base64.strict_encode64(encrypted_data + tag)}"
  end

  it { expect(encrypted).not_to eq("my_secret") }
  it { is_expected.to eq("my_secret") }

  context "when the encrypted value is not encrypted" do
    let(:encrypted) { "unencrypted secret" }

    it { is_expected.to eq("unencrypted secret") }
  end
end
