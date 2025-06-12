namespace :keys do
  desc "Clear unused keys"
  task clear_unused: :environment do
    Rails.logger.info "Clearing old api gateway keys..."
    api_gateway_ids = %w[taoe2sww37 cs0n1pvxf3 am1qh2dqxb r59xlgw39j 80j5gyiepb ukcm1syd06 fi4vrik61l 301ho7nd98 29twbg8h7i w64kjs82gi kwh3yd0qjh]

    api_keys = api_gateway_ids.map { |api_gateway_id| ApiKey.find_or_initialize_by(api_gateway_id:) }

    api_keys.each do |api_key|
      DeleteApiKey.new.call(api_key)
      Rails.logger.info "Deleted API key with ID: #{api_key.api_gateway_id}"
    end
    Rails.logger.info "#{api_keys.size} API keys deleted."
  end
end
