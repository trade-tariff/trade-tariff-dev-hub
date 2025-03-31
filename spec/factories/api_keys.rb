FactoryBot.define do
  factory :api_key do
    organisation
    api_key_id { "MyString" }
    api_gateway_id { "MyString" }
    enabled { false }
    secret { "MyString" }
    usage_plan_id { "MyString" }
    description { "An api key" }
  end
end
