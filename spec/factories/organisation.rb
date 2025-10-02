FactoryBot.define do
  factory :organisation do
    application_reference { "MyString" }
    description { "MyString" }
    eori_number { "MyString" }
    organisation_name { "MyString" }
    uk_acs_reference { "MyString" }

    trait :fpo do
      roles { [Role.find_by(name: "fpo:full")] }
    end
  end
end
