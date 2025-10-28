FactoryBot.define do
  factory :notification do
    email { "foo@bar.com" }
    template_id { "f6ef23c4-3159-4702-b854-939fbb5533e3" }
    personalisation { {} }
  end
end
