require "rails_helper"

RSpec.describe DeleteApiKey do
  subject(:delete_api_key) { described_class.new(api_gateway_client) }

  let(:api_gateway_client) { Aws::APIGateway::Client.new(stub_responses: true) }
  let(:api_key) { create(:api_key) }

  describe "#call" do
    context "when the result of deleting in api gateway is successful" do
      before { api_gateway_client.stub_responses(:delete_api_key) }

      it "deletes the api key" do
        delete_api_key.call(api_key)

        expect(ApiKey.exists?(api_key.id)).to be(false)
      end
    end

    context "when the result of deleting in api gateway is unsuccessful" do
      before { api_gateway_client.stub_responses(:delete_api_key, "error") }

      it "does not delete the api key", :aggregate_failures do
        expect { delete_api_key.call(api_key) }.to raise_error(StandardError)

        expect(ApiKey.exists?(api_key.id)).to be(true)
      end
    end
  end
end
