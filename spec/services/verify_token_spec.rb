RSpec.describe VerifyToken do
  let(:token) { "encoded-token" }

  before do
    allow(Rails.logger).to receive(:debug)
    allow(Rails.logger).to receive(:error)
  end

  def expect_invalid_result(result, reason)
    expect(result).to be_a(described_class::Result)
    expect(result).not_to be_valid
    expect(result.reason).to eq(reason)
    expect(result.payload).to be_nil
  end

  it "returns invalid result when no token is supplied" do
    expect_invalid_result(described_class.new(nil).call, :no_token)
  end

  it "returns invalid result when keys are missing outside development" do
    allow(Rails).to receive(:env).and_return("test".inquiry)
    allow(TradeTariffDevHub).to receive(:identity_cognito_jwks_keys).and_return(nil)
    expect_invalid_result(described_class.new(token).call, :no_keys)
  end

  context "with valid JWT setup" do
    before do
      allow(Rails).to receive(:env).and_return("development".inquiry)
      allow(TradeTariffDevHub).to receive(:identity_cognito_jwks_keys).and_return(nil)
      allow(DecryptToken).to receive(:new).with(token).and_return(instance_double(DecryptToken, call: token))
    end

    it "returns valid result with decoded payload when verification succeeds" do
      payload = { "cognito:groups" => %w[portal], "sub" => "test" }
      allow(TradeTariffDevHub).to receive(:identity_consumer).and_return("portal")
      allow(DecodeJwt).to receive(:new).with(token).and_return(instance_double(DecodeJwt, call: payload))
      result = described_class.new(token).call
      expect(result).to be_valid.and have_attributes(payload: payload)
    end

    it "returns expired result when token is expired" do
      allow(DecodeJwt).to receive(:new).with(token).and_raise(JWT::ExpiredSignature)
      result = described_class.new(token).call
      expect_invalid_result(result, :expired)
      expect(result).to be_expired
    end

    it "returns invalid result when user not in required group" do
      payload = { "cognito:groups" => %w[other-group] }
      allow(TradeTariffDevHub).to receive(:identity_consumer).and_return("portal")
      allow(DecodeJwt).to receive(:new).with(token).and_return(instance_double(DecodeJwt, call: payload))
      expect_invalid_result(described_class.new(token).call, :not_in_group)
    end

    it "returns invalid result when token is invalid" do
      allow(DecodeJwt).to receive(:new).with(token).and_raise(JWT::DecodeError)
      expect_invalid_result(described_class.new(token).call, :invalid)
    end
  end
end
