FactoryBot.define do
  factory :ott_key do
    organisation
    client_id { "OTT#{SecureRandom.alphanumeric(17)}" }
    secret { SecureRandom.hex(24) }
    description { "An OTT key" }
    scopes { %w[read write] }
  end
end
