FactoryBot.define do
  factory :organisation do
    authorised
    organisation_id { "MyString" }
    application_reference { "MyString" }
    description { "MyString" }
    eori_number { "MyString" }
    organisation_name { "MyString" }
    status { 1 }
    uk_acs_reference { "MyString" }

    trait :unregistered do
      status { :unregistered }
    end

    trait :authorised do
      status { :authorised }
    end

    trait :pending do
      status { :pending }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
