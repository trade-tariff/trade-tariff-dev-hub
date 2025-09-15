RSpec.describe DecodeJwt do
  describe "#call" do
    subject(:call) { described_class.new(token).call }

    let(:identity_cognito_jwks_url) { "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_eYCVlIQL0/.well-known/jwks.json" }
    let(:key_pair) { OpenSSL::PKey::RSA.generate(2048) }

    before do
      allow(TradeTariffDevHub).to receive(:identity_cognito_jwks_url).and_return(identity_cognito_jwks_url)
    end

    shared_examples_for "a call with an invalid token" do |invalid_token, error|
      let(:token) { invalid_token }

      it { expect { call }.to raise_error(error) }
    end

    context "when in production environment" do
      let(:token) do
        payload = {
          sub: "36b2a2b4-f021-70dd-b63e-d6adb1f6d519",
          iss: "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_eYCVlIQL0",
          aud: "b1ofbuedss7nncuh361fhf77n",
          email: "test@example.com",
          exp: (Time.zone.now + 1.day).to_i,
          iat: Time.zone.now.to_i,
          "cognito:groups" => %w[myott portal],
          "cognito:username" => "36b2a2b4-f021-70dd-b63e-d6adb1f6d519",
          email_verified: true,
          event_id: "1536b022-4ec9-4024-b9e1-315bbca4a3bd",
          token_use: "id",
          auth_time: Time.zone.now.to_i,
        }
        JWT.encode(payload, key_pair, "RS256", kid: "mock-kid")
      end

      let(:identity_cognito_jwks_keys) do
        if defined?(JWT::JWK)
          jwk = JWT::JWK.new(key_pair, kid: "mock-kid")
          [jwk.export]
        else
          [{
            "alg" => "RS256",
            "kid" => "mock-kid",
            "kty" => "RSA",
            "n" => Base64.urlsafe_encode64(key_pair.n.to_bn.to_s(2)),
            "e" => Base64.urlsafe_encode64(key_pair.e.to_bn.to_s(2)),
            "use" => "sig",
          }]
        end
      end

      let(:expected_decoded_token) do
        hash_including(
          "sub" => "36b2a2b4-f021-70dd-b63e-d6adb1f6d519",
          "iss" => "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_eYCVlIQL0",
          "aud" => "b1ofbuedss7nncuh361fhf77n",
          "email" => "test@example.com",
          "cognito:groups" => %w[myott portal],
          "cognito:username" => "36b2a2b4-f021-70dd-b63e-d6adb1f6d519",
          "email_verified" => true,
          "token_use" => "id",
        )
      end

      before do
        allow(TradeTariffDevHub).to receive(:identity_cognito_jwks_keys).and_return(identity_cognito_jwks_keys)
        allow(JWT).to receive(:decode).and_call_original
      end

      it "decodes the token" do
        expect(call).to match(expected_decoded_token)
      end

      it "calls JWT.decode with the correct parameters" do
        call
        expect(JWT).to have_received(:decode).with(token, nil, true, algorithms: %w[RS256],
                                                                     jwks: { keys: identity_cognito_jwks_keys },
                                                                     iss: "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_eYCVlIQL0",
                                                                     verify_iss: true)
      end

      it_behaves_like "a call with an invalid token", "", JWT::DecodeError
      it_behaves_like "a call with an invalid token", "invalid.token.here", JWT::DecodeError
      it_behaves_like "a call with an invalid token", "anything", JWT::InvalidIssuerError do
        let(:token) do
          payload = { sub: "test", iss: "https://wrong-issuer.com", exp: (Time.zone.now + 1.day).to_i }
          JWT.encode(payload, key_pair, "RS256", kid: "mock-kid")
        end
      end
      it_behaves_like "a call with an invalid token", "anything", JWT::ExpiredSignature do
        let(:token) do
          payload = { sub: "test", iss: "https://cognito-idp.eu-west-2.amazonaws.com/eu-west-2_eYCVlIQL0", exp: (Time.zone.now - 1.day).to_i }
          JWT.encode(payload, key_pair, "RS256", kid: "mock-kid")
        end
      end
    end

    context "when in development environment" do
      before do
        allow(Rails).to receive(:env).and_return("development".inquiry)
        allow(JWT).to receive(:decode).and_call_original
      end

      let(:token) do
        payload = { sub: "test", iss: "https://any-issuer.com", exp: (Time.zone.now + 1.day).to_i }
        JWT.encode(payload, "dummy-secret", "HS256")
      end

      it "decodes the token without verification" do
        expect(call).to include("sub" => "test", "iss" => "https://any-issuer.com")
      end

      it "calls JWT.decode without verification" do
        call
        expect(JWT).to have_received(:decode).with(token, nil, false)
      end

      it_behaves_like "a call with an invalid token", "", JWT::DecodeError
      it_behaves_like "a call with an invalid token", "invalid.token.here", JWT::DecodeError
    end
  end
end
