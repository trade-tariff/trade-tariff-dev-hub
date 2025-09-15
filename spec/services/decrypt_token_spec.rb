RSpec.describe DecryptToken do
  describe "#call" do
    subject(:call) { described_class.new(token).call }

    let(:secret) { "my-secret-key" }
    let(:key) { ActiveSupport::KeyGenerator.new(secret).generate_key("salt", 32) }
    let(:encryptor) { ActiveSupport::MessageEncryptor.new(key) }
    let(:token) { encryptor.encrypt_and_sign("my-token") }

    before do
      allow(TradeTariffDevHub).to receive(:identity_encryption_secret).and_return(secret)
    end

    it "decrypts the token" do
      expect(call).to eq("my-token")
    end

    context "when token is invalid" do
      let(:token) { "invalid-encrypted-token" }

      it "raises a decryption error" do
        expect { call }.to raise_error(ActiveSupport::MessageEncryptor::InvalidMessage)
      end
    end

    context "when token is empty" do
      let(:token) { "" }

      it "raises a decryption error" do
        expect { call }.to raise_error(ActiveSupport::MessageEncryptor::InvalidMessage)
      end
    end

    context "when in development environment" do
      let(:token) { "my-token" }

      before { allow(Rails).to receive(:env).and_return("development".inquiry) }

      it { expect(call).to eq("my-token") }
    end
  end

  describe ".crypt" do
    subject(:crypt) { described_class.crypt }

    let(:secret) { "my-secret-key" }

    before do
      allow(TradeTariffDevHub).to receive(:identity_encryption_secret).and_return(secret)
    end

    it "returns an ActiveSupport::MessageEncryptor instance" do
      expect(crypt).to be_a(ActiveSupport::MessageEncryptor)
    end

    it "generates a key with the correct secret and salt" do
      key = ActiveSupport::KeyGenerator.new(secret).generate_key("salt", 32)
      expect(crypt.instance_variable_get(:@secret)).to eq(key)
    end
  end
end
