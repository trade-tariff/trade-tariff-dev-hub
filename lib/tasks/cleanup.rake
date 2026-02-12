# frozen_string_literal: true

namespace :cleanup do
  desc "Delete API keys with description starting with 'playwright-' (dev only, all orgs)"
  task api_keys: :environment do
    allowed = Rails.env.development? || ENV["CLEANUP_PLAYWRIGHT_KEYS_ENABLED"] == "true"
    unless allowed
      next
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
