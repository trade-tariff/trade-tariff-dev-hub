# frozen_string_literal: true

namespace :cleanup do
  desc "Delete API keys with description starting with 'playwright-' (dev + admin org only)"
  task api_keys: :environment do
    allowed = Rails.env.development? || ENV["CLEANUP_PLAYWRIGHT_KEYS_ENABLED"] == "true"
    unless allowed
      next
    end

    admin_org = Organisation.admin_organisation
    if admin_org.blank?
      puts "Skipping: no admin organisation found"
      next
    end

    scope = admin_org.api_keys.where("description LIKE ?", "playwright-%")
    count = scope.count

    if count.zero?
      puts "No playwright API keys to delete"
      next
    end

    scope.find_each do |api_key|
      puts "Deleting API key: #{api_key.api_key_id} (#{api_key.description})"
      DeleteApiKey.new.call(api_key)
    end

    puts "Deleted #{count} playwright API key(s)"
  end
end
