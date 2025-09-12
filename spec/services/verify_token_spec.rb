RSpec.describe VerifyToken do
  describe "#call" do
    before do
      allow(Rails.logger).to receive(:debug)
      allow(Rails.logger).to receive(:error)
    end

    context "when the token is valid and the user is in the required group" do
      subject(:call) { described_class.new(token).call }

      let(:token) do
        payload = { sub: "test", iss: "https://any-issuer.com", exp: (Time.zone.now + 1.day).to_i, "cognito:groups" => %w[portal admin myott] }
        JWT.encode(payload, "dummy-secret", "HS256")
      end

      before do
        allow(Rails).to receive(:env).and_return("development".inquiry)
        allow(DecryptToken).to receive(:new).and_return(instance_double(DecryptToken, call: token))
        allow(TradeTariffDevHub).to receive_messages(
          identity_cognito_jwks_keys: nil,
          identity_cognito_issuer_url: "https://any-issuer.com",
          identity_consumer: "portal",
        )
      end

      it "returns the decoded token payload" do
        expect(call).to include("sub" => "test", "iss" => "https://any-issuer.com", "cognito:groups" => %w[portal admin myott])
      end
    end

    context "when the token is blank" do
      subject!(:call) { described_class.new(nil).call }

      it { is_expected.to be_nil }
      it { expect(Rails.logger).to have_received(:debug).with("No Cognito id token provided") }
    end

    context "when the token has expired" do
      subject(:call) { described_class.new(token).call }

      let(:token) do
        payload = { sub: "test", iss: "https://any-issuer.com", exp: (Time.zone.now - 1.day).to_i, "cognito:groups" => %w[portal] }
        JWT.encode(payload, "dummy-secret", "HS256")
      end

      before do
        allow(Rails).to receive(:env).and_return("development".inquiry)
        allow(DecryptToken).to receive(:new).and_return(instance_double(DecryptToken, call: token))
        allow(DecodeJwt).to receive(:new).and_raise(JWT::ExpiredSignature)
        call
      end

      it { is_expected.to be_nil }
      it { expect(Rails.logger).to have_received(:debug).with("Cognito id token has expired") }
    end

    context "when the token is invalid" do
      subject(:call) { described_class.new("invalid.token.here").call }

      before do
        allow(Rails).to receive(:env).and_return("development".inquiry)
        allow(DecryptToken).to receive(:new).and_return(instance_double(DecryptToken, call: "invalid.token.here"))
        allow(DecodeJwt).to receive(:new).and_raise(JWT::DecodeError)
        call
      end

      it { is_expected.to be_nil }
      it { expect(Rails.logger).to have_received(:debug).with("Cognito id token is invalid") }
    end

    context "when there are no JWKS keys and not in development environment" do
      subject(:call) { described_class.new("some-token").call }

      before do
        allow(TradeTariffDevHub).to receive(:identity_cognito_jwks_keys).and_return(nil)
        call
      end

      it { is_expected.to be_nil }
      it { expect(Rails.logger).to have_received(:error).with("No JWKS keys available to verify Cognito id token") }
    end

    context "when the user is not in the required group" do
      subject(:call) { described_class.new(token).call }

      let(:token) do
        payload = { sub: "test", iss: "https://any-issuer.com", exp: (Time.zone.now + 1.day).to_i, "cognito:groups" => %w[other-group] }
        JWT.encode(payload, "dummy-secret", "HS256")
      end

      before do
        allow(Rails).to receive(:env).and_return("development".inquiry)
        allow(DecryptToken).to receive(:new).and_return(instance_double(DecryptToken, call: token))
        allow(TradeTariffDevHub).to receive_messages(identity_cognito_jwks_keys: nil, identity_cognito_issuer_url: "https://any-issuer.com", identity_consumer: "portal")
        call
      end

      it { is_expected.to be_nil }
      it { expect(Rails.logger).to have_received(:error).with("Cognito id token user not in required group") }
    end
  end
end
