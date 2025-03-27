RSpec::Matchers.define :be_a_fpo_api_key_id do
  match do |actual|
    actual.match?(/\AHUB[0-9A-Z]{17}\z/i)
  end

  failure_message { |actual| "expected #{actual} to be a valid UUID" }
end
