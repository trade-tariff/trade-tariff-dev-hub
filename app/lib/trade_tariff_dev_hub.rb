module TradeTariffDevHub
  class << self
    def scp_enabled?
      ENV.fetch("SCP_ENABLED", "true") == "true"
    end

    def deletion_enabled?
      ENV.fetch("DELETION_ENABLED", "false") == "true"
    end

    def documentation_url
      ENV.fetch(
        "DOCUMENTATION_URL",
        "https://api.trade-tariff.service.gov.uk/fpo.html",
      )
    end

    def feedback_url
      ENV.fetch(
        "FEEDBACK_URL",
        "http://localhost:3001/feedback",
      )
    end

    def terms_and_conditions_url
      ENV.fetch(
        "TERMS_AND_CONDITIONS_URL",
        "https://api.trade-tariff.service.gov.uk/fpo/terms-and-conditions.html",
      )
    end

    def eori_lookup_url
      ENV.fetch("EORI_LOOKUP_URL", "https://test-api.service.hmrc.gov.uk/customs/eori/lookup/check-multiple-eori")
    end

    def govuk_notifier_api_key
      @govuk_notifier_api_key ||= ENV["GOVUK_NOTIFY_API_KEY"]
    end

    def application_support_email
      @application_support_email ||= ENV["APPLICATION_SUPPORT_EMAIL"]
    end

    def govuk_notifier_registration_template_id
      ENV["REGISTRATION_TEMPLATE_ID"]
    end

    def govuk_notifier_application_template_id
      ENV["SUPPORT_TEMPLATE_ID"]
    end

    def send_emails?
      ENV.fetch("SEND_EMAILS", "true") == "true"
    end
  end
end
