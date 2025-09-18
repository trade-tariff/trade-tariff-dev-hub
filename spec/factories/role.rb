FactoryBot.define do
  factory :role do
    name { "standard:read" }
    description { "foo" }

    trait :standard_read do
      name { "standard:read" }
    end

    trait :standard_write do
      name { "standard:write" }
    end
  end
end
