FactoryBot.define do
  factory :user do
    organisation
    email_address { "MyString@somewhat.com" }
    user_id { "MyString" }
  end
end
