FactoryBot.define do
  factory :role do
    fpo

    trait :trade_tariff do
      name { "trade_tariff:full" }
      description { "Full access to all features for Trade Tariff public APIs" }
    end

    trait :fpo do
      name { "fpo:full" }
      description { "Full access to all features for FPO" }
    end
  end
end
