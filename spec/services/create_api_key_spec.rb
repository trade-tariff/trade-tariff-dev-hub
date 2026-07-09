RSpec.describe CreateApiKey do
  subject(:create_api_key) { described_class.new(api_gateway_client) }

  let(:api_gateway_client) { Aws::APIGateway::Client.new(stub_responses: true) }
  let(:organisation) { create(:organisation) }
  let(:description) { "Test API Key" }
  let(:api_key) { ApiKey.new(organisation: organisation, description: description) }

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
          { id: "usage-plan-id-456", name: organisation.id },
        ],
        position: nil,
      )

      api_gateway_client.stub_responses(:create_usage_plan_key)
    end

    it "creates and saves an API key with valid responses", :aggregate_failures do
      result = create_api_key.call(api_key)

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

    it "does not create a new usage plan if one exists" do
      allow(api_gateway_client).to receive(:create_usage_plan)
      create_api_key.call(api_key)
      expect(api_gateway_client).not_to have_received(:create_usage_plan)
    end

    context "when save! fails after using a pre-existing usage plan" do
      before do
        allow(api_key).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        allow(api_gateway_client).to receive(:delete_api_key)
        allow(api_gateway_client).to receive(:delete_usage_plan)
        create_api_key.call(api_key)
      rescue ActiveRecord::RecordInvalid
        nil
      end

      it "deletes the API Gateway key from AWS" do
        expect(api_gateway_client).to have_received(:delete_api_key).with(
          api_key_id: "api-gateway-id-123",
        )
      end

      it "does not delete the pre-existing usage plan" do
        expect(api_gateway_client).not_to have_received(:delete_usage_plan)
      end
    end

    context "when save! fails after a new usage plan was created" do
      before do
        api_gateway_client.stub_responses(:get_usage_plans, items: [], position: nil)
        api_gateway_client.stub_responses(:create_usage_plan, id: "new-plan-id-789")
        allow(api_key).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        allow(api_gateway_client).to receive(:delete_api_key)
        allow(api_gateway_client).to receive(:delete_usage_plan)
        create_api_key.call(api_key)
      rescue ActiveRecord::RecordInvalid
        nil
      end

      it "deletes the newly created usage plan from AWS" do
        expect(api_gateway_client).to have_received(:delete_usage_plan).with(
          usage_plan_id: "new-plan-id-789",
        )
      end

      it "also deletes the API Gateway key from AWS" do
        expect(api_gateway_client).to have_received(:delete_api_key).with(
          api_key_id: "api-gateway-id-123",
        )
      end
    end
  end
end
