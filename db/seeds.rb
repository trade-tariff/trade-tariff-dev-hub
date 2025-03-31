if Rails.env.development?
  localstack_running = Timeout.timeout(1) do
    begin
      s = TCPSocket.new("host.docker.internal", "4566")
      s.close
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error, Socket::ResolutionError
      false
    end
  end

  org = Organisation.new(organisation_id: 'local-development', description: 'A friendly digital transformation agency').save

  if localstack_running
    CreateApiKey.new.call("local-development", "development API key")
    CreateApiKey.new.call("local-development", "staging API key")
    CreateApiKey.new.call("local-development", "production API key")
  else
    ApiKey.new(organisation_id: org.id, description: "development API key").save
    ApiKey.new(organisation_id: org.id, description: "staging API key").save
    ApiKey.new(organisation_id: org.id, description: "production API key").save
  end

  api_key = ApiKey.find_by(description: "staging API key")

  if localstack_running
    RevokeApiKey.new.call(api_key)
  else
    api_key.enabled = false
    api_key.save!
  end
end
