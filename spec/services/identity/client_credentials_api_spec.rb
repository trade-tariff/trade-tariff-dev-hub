# frozen_string_literal: true

RSpec.describe Identity::ClientCredentialsApi do
  subject(:api) { described_class.new(http_client: http_client) }

  let(:http_client) { instance_double(Faraday::Connection) }
  let(:base_url) { "http://identity.test/api/" }

  before do
    allow(TradeTariffDevHub).to receive_messages(identity_client_credentials_api_url: base_url, identity_api_key: "test-token")
  end

  describe "#create!" do
    let(:scopes) { %w[read write] }
    let(:response) { instance_double(Faraday::Response, status: 201, body: { "client_id" => "cognito-123", "client_secret" => "secret-456" }) }

    before do
      allow(http_client).to receive(:post).with("client_credentials") do |&block|
        req = instance_double(Faraday::Request, :body= => nil)
        block.call(req)
        response
      end
    end

    it "returns CreateResult with client_id and client_secret", :aggregate_failures do
      result = api.create!(scopes)

      expect(result).to be_a(Identity::ClientCredentialsApi::CreateResult)
      expect(result.client_id).to eq("cognito-123")
      expect(result.client_secret).to eq("secret-456")
    end

    it "maps read/write to tariff/read and tariff/write when sending to identity" do
      captured_body = nil
      allow(http_client).to receive(:post).with("client_credentials") do |&block|
        req = instance_double(Faraday::Request)
        allow(req).to receive(:body=) { |body| captured_body = body }
        block.call(req)
        response
      end

      api.create!(%w[read write])

      expect(captured_body).to eq({ scopes: %w[tariff/read tariff/write] })
    end

    context "when API returns 400" do
      let(:response) { instance_double(Faraday::Response, status: 400, body: { "error" => "scopes required" }.to_json) }

      before do
        allow(http_client).to receive(:post).and_return(response)
      end

      it "raises Error" do
        expect { api.create!(scopes) }.to raise_error(Identity::ClientCredentialsApi::Error, /400/)
      end
    end

    context "when API returns 201 but body missing client_id or client_secret" do
      let(:response) { instance_double(Faraday::Response, status: 201, body: { "client_id" => "id-123" }) }

      before do
        allow(http_client).to receive(:post).and_return(response)
      end

      it "raises Error" do
        expect { api.create!(scopes) }.to raise_error(Identity::ClientCredentialsApi::Error, /missing client_id or client_secret/)
      end
    end
  end

  describe "#delete" do
    let(:client_id) { "cognito-abc123" }

    before do
      allow(http_client).to receive(:delete).with("client_credentials/#{client_id}").and_return(instance_double(Faraday::Response, status: 204, body: nil))
    end

    it "sends DELETE with escaped client_id" do
      api.delete(client_id)

      expect(http_client).to have_received(:delete).with("client_credentials/#{client_id}")
    end

    it "returns true on 204" do
      expect(api.delete(client_id)).to be true
    end

    context "when API returns 404" do
      before do
        allow(http_client).to receive(:delete).and_return(instance_double(Faraday::Response, status: 404, body: nil))
      end

      it "returns true (treat as success)" do
        expect(api.delete(client_id)).to be true
      end
    end

    context "when API returns 401" do
      before do
        allow(http_client).to receive(:delete).and_return(instance_double(Faraday::Response, status: 401, body: "Unauthorized"))
      end

      it "raises Error" do
        expect { api.delete(client_id) }.to raise_error(Identity::ClientCredentialsApi::Error, /401/)
      end
    end
  end
end
