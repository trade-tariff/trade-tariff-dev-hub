RSpec.describe RevokeApiKey do
  subject(:revoke_api_key) { described_class.new(api_gateway_client) }

  let(:api_gateway_client) { Aws::APIGateway::Client.new(stub_responses: true) }
  let(:api_key) { create(:api_key, api_gateway_id: "api-gateway-id-123", enabled: true) }

  describe "#call" do
    context "when the result of revoking api gateway is successful" do
      before do
        api_gateway_client.stub_responses(
          :update_api_key,
          id: api_key.api_gateway_id,
          name: api_key.api_key_id,
          description: api_key.description,
          enabled: false,
        )
      end

      it "changes the api key enabled flag to `false`" do
        expect { revoke_api_key.call(api_key) }
          .to change { api_key.reload.enabled }.from(true).to(false)
      end
    end

    context "when the result of revoking in api gateway is unsuccessful" do
      before do
        api_gateway_client.stub_responses(:update_api_key, "error")
      end

      it "does not change the api key enabled flag to `false`", :aggregate_failures do
        expect { revoke_api_key.call(api_key) }.to raise_error(StandardError)

        expect(api_key.reload.enabled).to be(true)
      end
    end
  end
end
