FactoryBot.define do
  factory :user do
    organisation
    sequence(:email_address) { |n| "user#{n}@example.com" }
    sequence(:user_id) { |n| "user_id_#{n}" }
  end
end
