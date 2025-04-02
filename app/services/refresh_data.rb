class RefreshData
  def initialize(dynamo_db_client = Aws::DynamoDB::Client.new, api_gateway_client = Aws::APIGateway::Client.new)
    @dynamo_db_client = dynamo_db_client
    @api_gateway_client = api_gateway_client
    @organisations = {}
  end

  def call
    upsert_organisations
    upsert_users
    upsert_api_keys
  end

private

  attr_reader :dynamo_db_client, :api_gateway_client, :organisations

  def upsert_organisations
    organisations_data = dynamo_db_client.scan(table_name: "Organisations").items.map do |org|
      {
        application_reference: org["ApplicationReference"],
        created_at: org["CreatedAt"],
        description: org["Description"],
        eori_number: org["EoriNumber"],
        organisation_id: org["OrganisationId"],
        organisation_name: org["OrganisationName"],
        status: Organisation.statuses[org["Status"].downcase],
        uk_acs_reference: org["UkAcsReference"],
        updated_at: Time.current,
      }
    end

    Organisation.upsert_all(organisations_data, unique_by: :organisation_id)

    external_ids = organisations_data.map { |o| o[:organisation_id] }
    @organisations = Organisation.where(organisation_id: external_ids).pluck(:organisation_id, :id).to_h
  end

  def upsert_users
    users_data = dynamo_db_client.scan(table_name: "Users").items.map { |user|
      external_org_id = user["OrganisationId"]
      organisation_id = organisations[external_org_id]
      next if organisation_id.blank?

      {
        created_at: user["CreatedAt"],
        email_address: user["EmailAddress"].presence || "none specified",
        organisation_id: organisation_id,
        user_id: user["UserId"],
        updated_at: Time.current,
      }
    }.compact

    User.upsert_all(users_data, unique_by: %i[user_id organisation_id])
  end

  def upsert_api_keys
    api_keys_data = dynamo_db_client.scan(table_name: "CustomerApiKeys").items.map { |api_key|
      external_org_id = api_key["OrganisationId"]
      organisation_id = organisations[external_org_id]
      next if organisation_id.blank?

      {
        api_gateway_id: api_key["ApiGatewayId"],
        api_key_id: api_key["CustomerApiKeyId"],
        created_at: api_key["CreatedAt"],
        description: api_key["Description"],
        enabled: api_key["Enabled"],
        organisation_id: organisation_id,
        secret: DecryptSecret.new.call(api_key["Secret"]),
        usage_plan_id: usage_plans[api_key["CustomerApiKeyId"]],
        updated_at: Time.current,
      }
    }.compact

    ApiKey.upsert_all(api_keys_data, unique_by: %i[api_key_id organisation_id])
  end

  def usage_plans
    @usage_plans ||= api_gateway_client.get_usage_plans.items.each_with_object({}) do |usage_plan, acc|
      api_gateway_client.get_usage_plan_keys(usage_plan_id: usage_plan.id).items.each do |key|
        acc[key["name"]] = usage_plan["id"]
      end
    end
  end
end
