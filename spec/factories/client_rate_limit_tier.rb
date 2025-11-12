FactoryBot.define do
  factory :client_rate_limit_tier do
    sequence(:name) { |n| "tier_#{n}" }
    refill_rate { 100 }
    refill_interval { 60 }
    refill_max { 200 }
  end
end
