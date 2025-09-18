require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rspec/rails"

begin
  ActiveRecord::Migration.maintain_test_schema!

  Role.create!(name: "standard:read", description: "foo") if Role.where(name: "standard:read").empty?
  Role.create!(name: "fpo:read", description: "foo") if Role.where(name: "fpo:read").empty?
  Role.create!(name: "spimm:read", description: "foo") if Role.where(name: "spimm:read").empty?
  Role.create!(name: "admin:full", description: "foo") if Role.where(name: "admin:full").empty?
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
