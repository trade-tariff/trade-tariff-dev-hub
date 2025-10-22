FactoryBot.define do
  factory :session do
    user
    token { SecureRandom.uuid }
    id_token { "placeholder-id-token" }
  end
end
