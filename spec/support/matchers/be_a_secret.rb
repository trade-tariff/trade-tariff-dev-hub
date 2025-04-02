RSpec::Matchers.define :be_a_secret do
  match do |actual|
    actual.match?(/\A[0-9a-f]{#{CreateApiKey::SECRET_LENGTH}}\z/i)
  end

  failure_message { |actual| "expected #{actual} to be a valid UUID" }
end
