FactoryBot.define do
  factory :trade_tariff_key do
    organisation
    client_id { "TT#{SecureRandom.alphanumeric(18)}" }
    secret { SecureRandom.hex(24) }
    description { "A Trade Tariff key" }
    scopes { %w[read write] }
    api_gateway_id { nil }
    usage_plan_id { nil }

    trait :cognito_provisioned do
      client_id { "cognito-#{SecureRandom.alphanumeric(16)}" }
      secret { nil }
      api_gateway_id { "agw-#{SecureRandom.hex(8)}" }
      usage_plan_id { "usage-plan-#{SecureRandom.hex(4)}" }
    end
  end
end
