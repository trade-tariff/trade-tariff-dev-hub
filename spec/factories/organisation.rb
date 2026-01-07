FactoryBot.define do
  factory :organisation do
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
  end
end
