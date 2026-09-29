# frozen_string_literal: true

namespace :cleanup do
  desc "Delete playwright- API keys across all organisations (development only, explicit opt-in required)"
  task api_keys: :environment do
    unless TradeTariffDevHub.environment == "development" && ENV["CLEANUP_PLAYWRIGHT_KEYS_ENABLED"] == "true"
      abort "Cleanup requires ENVIRONMENT=development and CLEANUP_PLAYWRIGHT_KEYS_ENABLED=true"
    end

    scope = ApiKey.where("description LIKE ?", "playwright-%")
    count = scope.count

    if count.zero?
      puts "No playwright API keys to delete"
      next
    end

    total_deleted = 0
    scope.find_each do |api_key|
      puts "Deleting API key: #{api_key.api_key_id} (#{api_key.description}) from org: #{api_key.organisation.organisation_name}"
      DeleteApiKey.new.call(api_key)
      total_deleted += 1
    end

    puts "Deleted #{total_deleted} playwright API key(s)"
  end
end
