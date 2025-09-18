FactoryBot.define do
  factory :role do
    name { "ott:full" }
    description { "foo" }

    trait :standard_read do
      name { "ott:full" }
    end

    trait :standard_write do
      name { "standard:write" }
    end
  end
end
