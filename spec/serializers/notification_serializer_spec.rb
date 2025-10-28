RSpec.describe NotificationSerializer do
  let(:notification) { build(:notification) }

  describe "#serializable_hash" do
    subject(:serialized_notification) { described_class.new(notification).serializable_hash }

    let(:expected_pattern) do
      {
        data: {
          attributes: {
            email: match(URI::MailTo::EMAIL_REGEXP),
            email_reply_to_id: be_nil,
            personalisation: be_empty,
            reference: match(/\APORTAL-[A-Z0-9]{10}\z/),
            template_id: match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i),
          },
          type: eq(:notification),
        },
      }
    end

    it { is_expected.to include_json(expected_pattern) }
  end
end
