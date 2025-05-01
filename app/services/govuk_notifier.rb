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
    # TODO: Implement audit logging via backend audit api
  end
end
