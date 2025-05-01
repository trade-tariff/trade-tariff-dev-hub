# TODO: one_click_unsubscribe_url https://docs.notifications.service.gov.uk/ruby.html#one-click-unsubscribe-url-recommended
class GovukNotifier
  delegate :govuk_notifier_api_key, to: TradeTariffDevHub

  def initialize(client = nil)
    @client = client || Notifications::Client.new(govuk_notifier_api_key)
  end

  def call(email_address, template_id, personalisation = {})
    form_data = {
      email_address: email_address,
      template_id: template_id,
      personalisation: personalisation,
    }
    form_data[:reference] = personalisation[:reference] if personalisation[:reference]

    email_response = @client.send_email(form_data)

    audit(email_response)
  rescue Notifications::Client::RequestError => e
    raise e
  end

private

  def audit(email_response)
    GovukNotifierAudit.create(
      notification_uuid: email_response["id"],
      subject: email_response["content"]["subject"],
      body: email_response["content"]["body"],
      from_email: email_response["content"]["from_email"],
      template_id: email_response["template"]["id"],
      template_version: email_response["template"]["version"],
      template_uri: email_response["template"]["uri"],
      notification_uri: email_response["uri"],
    )
  end
end
