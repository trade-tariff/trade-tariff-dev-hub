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

    def cors_host
      ENV.fetch("GOVUK_APP_DOMAIN", "*").sub(/https?:\/\//, "")
    end

    def identity_consumer_url
      @identity_consumer_url ||= URI.join(identity_base_url, identity_consumer).to_s
    end

    def identity_base_url
      ENV.fetch("IDENTITY_BASE_URL", "http://localhost:3005")
    end

    def identity_encryption_secret
      ENV["IDENTITY_ENCRYPTION_SECRET"]
    end

    def identity_consumer
      @identity_consumer ||= ENV.fetch("IDENTITY_CONSUMER", "portal")
    end

    def identity_cognito_jwks_keys
      Rails.cache.fetch("identity_cognito_jwks_keys", expires_in: 1.hour) do
        response = Faraday.get(identity_cognito_jwks_url)

        return JSON.parse(response.body)["keys"] if response.success?

        Rails.logger.error("Failed to fetch JWKS keys: #{response.status} #{response.body}")

        nil
      end
    end

    def identity_cognito_jwks_url
      @identity_cognito_jwks_url ||= ENV["IDENTITY_COGNITO_JWKS_URL"]
    end
  end
end
