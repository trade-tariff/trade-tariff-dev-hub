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

  if localstack_running
    Aws.config.update({
      region: 'us-east-1',
      endpoint: 'http://localhost:4566',
      credentials: Aws::Credentials.new('dummy', 'dummy')
    })

    api_gateway_client = Aws::APIGateway::Client.new
    rest_api_name = "development-trade-tariff-lambdas-fpo-search"

    response = api_gateway_client.get_rest_apis
    rest_api = response.items.find { |api| api.name == rest_api_name }

    unless rest_api
      response = api_gateway_client.create_rest_api(name: rest_api_name)
      rest_api = response.id.presence || raise("Failed to create REST API")
    end

    ENV['REST_API_ID'] = rest_api.try(:id) || rest_api
  end
end
