FactoryBot.define do
  factory :trade_tariff_key do
    organisation
    client_id { "TT#{SecureRandom.alphanumeric(18)}" }
    secret { SecureRandom.hex(24) }
    description { "A Trade Tariff key" }
    scopes { %w[read write] }
  end
end
