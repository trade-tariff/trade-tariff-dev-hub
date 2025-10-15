FactoryBot.define do
  factory :invitation do
    sequence(:invitee_email) { |n| "invitee#{n}@example.com" }
    user
    organisation { user.organisation }
    status { "pending" }
  end
end
