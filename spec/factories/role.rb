FactoryBot.define do
  factory :role do
    fpo

    trait :ott do
      name { "ott:full" }
      description { "Full access to all features for OTT public APIs" }
    end

    trait :fpo do
      name { "fpo:full" }
      description { "Full access to all features for FPO" }
    end
  end
end
