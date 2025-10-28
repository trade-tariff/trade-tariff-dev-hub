RSpec.describe SendNotification do
  subject(:send_notification) { described_class.new(notification) }

  describe "#call" do
    let(:notification) { build(:notification) }

    context "when the notification is sent successfully" do
      before do
        stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
          .to_return(
            status: 202,
            body: '{"data":{"id":"67cc2850-f82c-4215-96ac-a56554bc156e","type":"notification"}}',
            headers: { "Content-Type" => "application/json" },
          )
      end

      it { expect(send_notification.call).to be true }

      it "logs an info message" do
        allow(Rails.logger).to receive(:info)
        send_notification.call
        expect(Rails.logger).to have_received(:info).with("Notification enqueued successfully: 67cc2850-f82c-4215-96ac-a56554bc156e")
      end
    end

    context "when the notification is unauthorized" do
      before do
        stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
          .to_return(status: 401, body: "Unauthorized", headers: {})
      end

      it { expect(send_notification.call).to be false }

      it "logs an error message" do
        allow(Rails.logger).to receive(:error)
        send_notification.call
        expect(Rails.logger).to have_received(:error).with("Unauthorized to send notification: Unauthorized")
      end
    end

    context "when there is a validation error sending the notification" do
      let(:validation_errors) do
        {
          "errors" => [
            {
              "status" => 422,
              "title" => "must be a valid e-mail address",
              "detail" => "Email must be a valid e-mail address",
              "source" => { "pointer" => "/data/attributes/email" },
            },
            {
              "status" => 422,
              "title" => "must be a valid UUID",
              "detail" => "Template must be a valid UUID",
              "source" => { "pointer" => "/data/attributes/template_id" },
            },
          ],
        }.to_json
      end

      before do
        stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
          .to_return(
            status: 422,
            body: validation_errors,
            headers: { "Content-Type" => "application/json" },
          )
      end

      it { expect(send_notification.call).to be false }

      it "logs the validation error" do
        allow(Rails.logger).to receive(:error)
        send_notification.call
        expect(Rails.logger).to have_received(:error).with("Validation error sending notification: #{JSON.parse(validation_errors)}")
      end
    end

    context "when the notification fails to send" do
      before do
        stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
          .to_return(status: 500, body: "Internal Server Error", headers: {})
      end

      it { expect(send_notification.call).to be false }

      it "logs an error and returns false" do
        allow(Rails.logger).to receive(:error)
        send_notification.call
        expect(Rails.logger).to have_received(:error).with(/Failed to send notification: 500 Internal Server Error/)
      end
    end
  end
end
