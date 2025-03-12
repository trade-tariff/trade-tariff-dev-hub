FactoryBot.define do
  factory :user do
    organisation
    email_address { "MyString" }
    user_id { "MyString" }
  end
end
