FactoryBot.define do
  factory :role_request do
    organisation
    user
    role_name { "fpo:full" }
    note { "I need access to manage FPO API keys" }
    status { "pending" }

    trait :approved do
      status { "approved" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end
