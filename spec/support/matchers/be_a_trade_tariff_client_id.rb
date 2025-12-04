RSpec::Matchers.define :be_a_trade_tariff_client_id do
  match do |actual|
    actual.is_a?(String) &&
      actual.starts_with?("TT") &&
      actual.length == 20 # "TT" + 18 characters
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be a Trade Tariff client ID (starting with TT and 20 characters long)"
  end
end
