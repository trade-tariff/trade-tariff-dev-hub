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

  org = Organisation.new(organisation_id: 'local-development', description: 'A friendly digital transformation agency')
  org.save

  if localstack_running
    CreateApiKey.new.call("local-development", "development API key")
    CreateApiKey.new.call("local-development", "staging API key")
    CreateApiKey.new.call("local-development", "production API key")
  else
    ApiKey.new(
      organisation_id: org.id,
      description: "development API key",
      api_key_id: "development-api-key",
      api_gateway_id: "development-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    ).save
    ApiKey.new(
      organisation_id: org.id,
      description: "staging API key",
      api_key_id: "staging-api-key",
      api_gateway_id: "staging-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    ).save
    ApiKey.new(
      organisation_id: org.id,
      description: "production API key",
      api_key_id: "production-api-key",
      api_gateway_id: "production-api-gateway-id",
      secret: "foo",
      usage_plan_id: "usage-plan-id",
    ).save
  end

  api_key = ApiKey.find_by(description: "staging API key")

  if localstack_running
    RevokeApiKey.new.call(api_key)
  else
    api_key.enabled = false
    api_key.save!
  end
end
