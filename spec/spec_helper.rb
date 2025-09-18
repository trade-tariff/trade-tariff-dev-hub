RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.before(:suite) do
    Role.create!(name: "standard:read", description: "foo") if Role.where(name: "standard:read").empty?
    Role.create!(name: "fpo:read", description: "foo") if Role.where(name: "fpo:read").empty?
    Role.create!(name: "spimm:read", description: "foo") if Role.where(name: "spimm:read").empty?
    Role.create!(name: "admin:full", description: "foo") if Role.where(name: "admin:full").empty?
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
