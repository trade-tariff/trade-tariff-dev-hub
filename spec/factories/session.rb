FactoryBot.define do
  factory :session do
    current
    user
    token { SecureRandom.uuid }

    raw_info do
      {
        "bas:groupId": "flibble",
        "bas:groupProfile": "https://www.ete.access.service.gov.uk/groupprofile/flibble",
        "bas:roles": %w[Administrator User],
        "email": "foo@bar.com",
        "email_verified": true,
        "name": "Samwise Gamgee",
        "profile": "https://www.ete.access.service.gov.uk/profile/samwise",
        "sub": "1234567890",
        "exp": 1_748_956_674,
      }
    end

    trait :current do
      expires_at { Time.zone.now + 1.hour }
    end

    trait :expired do
      expires_at { Time.zone.now - 1.hour }
    end
  end
end
