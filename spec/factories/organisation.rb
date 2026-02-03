FactoryBot.define do
  factory :organisation do
    # NOTE: Default role is FPO to handle most common path through application. Other roles are currently prohibited until functionality is fully and not partially available
    fpo

    sequence(:organisation_name) { |n| "Test Organisation #{n}" }
    application_reference { "MyString" }
    description { "MyString" }
    eori_number { "MyString" }
    uk_acs_reference { "MyString" }

    trait :fpo do
      roles { [Role.find_by(name: "fpo:full")] }
    end

    trait :admin do
      roles { [Role.find_by(name: "admin")] }
    end

    trait :implicit do
      roles { [] }
    end

    trait :trade_tariff_only do
      roles { [Role.find_by(name: "trade_tariff:full")] }
    end
  end
end
