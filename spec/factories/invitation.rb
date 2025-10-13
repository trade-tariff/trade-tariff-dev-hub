FactoryBot.define do
  factory :invitation do
    invitee_email { "foo@bar.com" }
    user
    organisation { user.organisation }
    status { "pending" }
  end
end
