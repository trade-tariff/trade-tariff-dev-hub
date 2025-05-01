RSpec.describe GovukNotifier do
  describe "#call" do
    subject(:call) { service.call("foo@bar.com", "b0f0c2b2-c5f5-4f3a-8d9c-f4c8e8ea1a7c", { foo: "bar" }) }

    let(:service) { described_class.new(client) }
    let(:client) { instance_double(Notifications::Client, send_email: response) }
    let(:last_audit) { GovukNotifierAudit.first }

    let(:response) do
      {
        "id" => SecureRandom.uuid,
        "reference" => nil,
        "content" => {
          "body" => "test",
          "subject" => "test",
          "from_email" => "foo@bar.com",
        },
        "template" => {
          "id" => "b0f0c2b2-c5f5-4f3a-8d9c-f4c8e8ea1a7c",
          "version" => 1,
          "uri" => "/v2/templates/b0f0c2b2-c5f5-4f3a-8d9c-f4c8e8ea1a7c",
        },
        "uri" => "/notifications/aceed36e-6aee-494c-a09f-88b68904bad6",
      }
    end

    before { call }

    it "sends an email" do
      expect(client).to have_received(:send_email).with(
        email_address: "foo@bar.com",
        template_id: "b0f0c2b2-c5f5-4f3a-8d9c-f4c8e8ea1a7c",
        personalisation: { foo: "bar" },
      )
    end
  end
end
