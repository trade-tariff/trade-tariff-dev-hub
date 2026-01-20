FactoryBot.define do
  factory :api_key do
    organisation
    sequence(:api_key_id) { |n| "api_key_#{n}" }
    sequence(:api_gateway_id) { |n| "api_gateway_#{n}" }
    enabled { true }
    secret { "MyString" }
    usage_plan_id { "MyString" }
    description { "An api key" }
  end
end
