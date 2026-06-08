require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
ENV["ENVIRONMENT"] ||= "test" # Not live production; key limits and deploy-specific behaviour stay off in test
ENV["DISABLE_BOOTSNAP_COMPILE_CACHE"] ||= "1" # SimpleCov starts Ruby coverage before Rails boots

require "simplecov"

SimpleCov.start "rails"
SimpleCov.formatters = SimpleCov::Formatter::HTMLFormatter

# Stub dev_bypass_auth_enabled? before loading environment so routes are available
# This allows the conditional routes in config/routes.rb to be loaded in test
allow(TradeTariffDevHub).to receive(:dev_bypass_auth_enabled?).and_return(true) if defined?(TradeTariffDevHub)

require_relative "../config/environment"
require "rspec/rails"

begin
  ActiveRecord::Migration.maintain_test_schema!

  Role.find_or_create_by!(name: "trade_tariff:full") { |role| role.description = "foo" }
  Role.find_or_create_by!(name: "fpo:full") { |role| role.description = "foo" }
  Role.find_or_create_by!(name: "admin") { |role| role.description = "foo" }
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join("spec/fixtures"),
  ]
  config.include FactoryBot::Syntax::Methods
  config.use_transactional_fixtures = true

  config.filter_rails_from_backtrace!
end
