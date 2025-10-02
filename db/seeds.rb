[
  {
    name: 'admin',
    description: 'Full access to all features and settings',
  },
  {
    name: 'fpo:full',
    description: 'Full access to FPO (Fast Parcel Operator) API keys'
  },
  {
    name: 'ott:full',
    description: 'Full access to Online Trade Tariff public API keys',
  },
  {
    name: 'spimm:full',
    description: 'Full access to SPIMM (Simplified Process for Internal Market Movements) API keys.'
  }
].each do |role_attrs|
  Role.find_or_create_by(role_attrs)
end

if Rails.env.development?
  localstack_running = Timeout.timeout(1) do
    begin
      s = TCPSocket.new(ENV['LOCALSTACK_HOST'], "4566")
      s.close
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error, Socket::ResolutionError
      false
    end
  end

  user = User.dummy_user!
  organisation = user.organisation
  organisation.assign_role!("fpo:full")
  organisation.assign_role!("ott:full")

  if localstack_running
    CreateApiKey.new.call("local-development", "development API key")
    CreateApiKey.new.call("local-development", "staging API key")
    CreateApiKey.new.call("local-development", "production API key")
  else
    ApiKey.create(
      organisation_id: organisation.id,
      description: "development API key",
      api_key_id: "development-api-key",
      api_gateway_id: "development-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    )
    ApiKey.create(
      organisation_id: organisation.id,
      description: "staging API key",
      api_key_id: "staging-api-key",
      api_gateway_id: "staging-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    )
    ApiKey.create(
      organisation_id: organisation.id,
      description: "production API key",
      api_key_id: "production-api-key",
      api_gateway_id: "production-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    )
  end

  api_key = ApiKey.find_by(description: "staging API key")

  if localstack_running
    RevokeApiKey.new.call(api_key)
  else
    api_key.enabled = false
    api_key.save!
  end
end
