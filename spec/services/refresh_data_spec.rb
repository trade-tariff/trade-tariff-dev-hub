RSpec.describe RefreshData do
  subject(:call) { described_class.new(dynamo_db_client, api_gateway_client).call }

  let(:dynamo_db_client) { Aws::DynamoDB::Client.new(stub_responses: true) }
  let(:api_gateway_client) { Aws::APIGateway::Client.new(stub_responses: true) }

  let(:scan_responses) do
    {
      "Organisations" => {
        items: [
          {
            "ApplicationReference" => "app-ref",
            "CreatedAt" => "2022-01-01T00:00:00Z",
            "Description" => "desc",
            "EoriNumber" => "eori",
            "OrganisationId" => "org-id",
            "OrganisationName" => "org-name",
            "Status" => "Authorised",
            "UkAcsReference" => "uk-acs-ref",
          },
        ],
      },
      "Users" => {
        items: [
          {
            "CreatedAt" => "2022-01-01T00:00:00Z",
            "EmailAddress" => "user@example.com",
            "OrganisationId" => "org-id",
            "UserId" => "user-id",
          },
        ],
      },
      "CustomerApiKeys" => {
        items: [
          {
            "ApiGatewayId" => "api-gateway-id",
            "CustomerApiKeyId" => "api-key-id",
            "CreatedAt" => "2022-01-01T00:00:00Z",
            "Description" => "api-key-desc",
            "Enabled" => true,
            "OrganisationId" => "org-id",
            "Secret" => "z+yfb24gC+H5VT3o:P+b43wtaUOH26G2taA9khZ3S4YxOw3f/fg==",
          },
        ],
      },
    }
  end

  before do
    scan_table = ->(context) { scan_responses[context.params[:table_name]] }

    api_gateway_client.stub_responses(:get_usage_plans, items: [{ id: "usage-plan-id" }])
    api_gateway_client.stub_responses(:get_usage_plan_keys, items: [{ name: "api-key-id", id: "usage-plan-id" }])
    dynamo_db_client.stub_responses(:scan, scan_table)

    allow(DecryptSecret).to receive(:new).and_call_original
  end

  describe "#call" do
    it "creates organisations" do
      call

      expect(Organisation.all.as_json).to match(
        [
          a_hash_including({
            "id" => be_a_uuid,
            "organisation_id" => "org-id",
            "application_reference" => "app-ref",
            "description" => "desc",
            "eori_number" => "eori",
            "organisation_name" => "org-name",
            "status" => "authorised",
            "uk_acs_reference" => "uk-acs-ref",
            "created_at" => "2022-01-01T00:00:00.000Z",
            "updated_at" => be_present,
          }),
        ],
      )
    end

    it "creates users" do
      call

      expect(User.all.as_json).to match(
        [
          {
            "id" => be_a_uuid,
            "organisation_id" => be_a_uuid,
            "email_address" => "user@example.com",
            "user_id" => "user-id",
            "created_at" => "2022-01-01T00:00:00.000Z",
            "updated_at" => be_present,
          },
        ],
      )
    end

    it "creates api keys" do
      call

      expect(ApiKey.all.as_json).to match(
        [
          {
            "id" => be_a_uuid,
            "organisation_id" => be_a_uuid,
            "api_key_id" => "api-key-id",
            "api_gateway_id" => "api-gateway-id",
            "enabled" => true,
            "secret" => "my_secret",
            "usage_plan_id" => "usage-plan-id",
            "description" => "api-key-desc",
            "created_at" => "2022-01-01T00:00:00.000Z",
            "updated_at" => be_present,
          },
        ],
      )
    end
  end
end
