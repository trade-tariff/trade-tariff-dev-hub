RSpec::Matchers.define :be_an_ott_client_id do
  match do |actual|
    actual.is_a?(String) &&
      actual.starts_with?("OTT") &&
      actual.length == 20 # "OTT" + 17 characters
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be an OTT client ID (starting with OTT and 20 characters long)"
  end
end
