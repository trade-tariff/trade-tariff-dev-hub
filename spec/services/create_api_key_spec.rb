require "rails_helper"

RSpec.describe CreateApiKey do
  subject(:create_api_key) { described_class.new(api_gateway_client) }

  let(:api_gateway_client) { Aws::APIGateway::Client.new(stub_responses: true) }
  let(:organisation) { create(:organisation, organisation_id: "org-123") }
  let(:description) { "Test API Key" }

  describe "#call" do
    before do
      api_gateway_client.stub_responses(
        :create_api_key,
        id: "api-gateway-id-123",
        name: "HUBABCDEFGHIJKLMNOPQ",
        description: description,
        enabled: true,
      )

      api_gateway_client.stub_responses(
        :get_usage_plans,
        items: [
          { id: "usage-plan-id-456", name: "org-123" },
        ],
        position: nil,
      )

      api_gateway_client.stub_responses(:create_usage_plan_key)
    end

    # rubocop:disable RSpec/ExampleLength
    it "creates and saves an API key with valid responses", :aggregate_failures do
      result = create_api_key.call(organisation.organisation_id, description)

      expect(result.id).to be_a_uuid
      expect(result.organisation_id).to eq(organisation.id)
      expect(result.secret).to be_a_secret
      expect(result.api_key_id).to be_a_fpo_api_key_id
      expect(result.enabled).to be(true)
      expect(result.description).to eq(description)
      expect(result.created_at).to be_present
      expect(result.updated_at).to be_present
      expect(result).to be_persisted
    end
    # rubocop:enable RSpec/ExampleLength

    it "does not create a new usage plan if one exists" do
      allow(api_gateway_client).to receive(:create_usage_plan)
      create_api_key.call(organisation.organisation_id, description)
      expect(api_gateway_client).not_to have_received(:create_usage_plan)
    end
  end
end
