module TradeTariffDevHub
  class << self
    def govuk_app_domain
      @govuk_app_domain ||= ENV.fetch(
        "GOVUK_APP_DOMAIN",
        "https://localhost:3004",
      )
    end

    def identity_authentication_enabled?
      @identity_authentication_enabled ||= ENV.fetch("IDENTITY_AUTHENTICATION_ENABLED", "true") == "true"
    end

    def deletion_enabled?
      ENV.fetch("DELETION_ENABLED", "false") == "true"
    end

    def role_request_enabled?
      ENV.fetch("FEATURE_FLAG_ROLE_REQUEST", "false") == "true"
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

    def govuk_notifier_api_key
      @govuk_notifier_api_key ||= ENV["GOVUK_NOTIFY_API_KEY"]
    end

    def application_support_email
      @application_support_email ||= ENV["APPLICATION_SUPPORT_EMAIL"] || "dev@example.com"
    end

    def cors_host
      ENV.fetch("GOVUK_APP_DOMAIN").sub(/https?:\/\//, "")
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
      return if identity_cognito_jwks_url.blank?

      Rails.cache.fetch("identity_cognito_jwks_keys", expires_in: 1.hour) do
        Rails.logger.info("[Auth] Fetching JWKS keys from: #{identity_cognito_jwks_url}")
        response = Faraday.get(identity_cognito_jwks_url)

        if response.success?
          keys = JSON.parse(response.body)["keys"]
          Rails.logger.info("[Auth] Successfully fetched #{keys&.size || 0} JWKS keys")
          keys
        else
          Rails.logger.error("[Auth] Failed to fetch JWKS keys: HTTP #{response.status}")
          Rails.logger.error("[Auth] JWKS response body: #{response.body&.truncate(500)}")
          nil
        end
      end
    rescue Faraday::ConnectionFailed => e
      Rails.logger.error("[Auth] JWKS connection failed: #{e.message}")
      Rails.logger.error("[Auth] JWKS URL was: #{identity_cognito_jwks_url}")
      nil
    rescue Faraday::TimeoutError => e
      Rails.logger.error("[Auth] JWKS request timed out: #{e.message}")
      nil
    rescue Faraday::ClientError => e
      Rails.logger.error("[Auth] JWKS client error (4xx): #{e.message}")
      Rails.logger.error("[Auth] JWKS URL was: #{identity_cognito_jwks_url}")
      nil
    rescue Faraday::ServerError => e
      Rails.logger.error("[Auth] JWKS server error (5xx): #{e.message}")
      nil
    rescue JSON::ParserError => e
      Rails.logger.error("[Auth] Failed to parse JWKS response as JSON: #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.error("[Auth] Unexpected error fetching JWKS keys: #{e.class}: #{e.message}")
      nil
    end

    def identity_cognito_jwks_url
      @identity_cognito_jwks_url ||= ENV["IDENTITY_COGNITO_JWKS_URL"]
    end

    def identity_cognito_issuer_url
      URI(identity_cognito_jwks_url).tap { |uri|
        uri.path = "/#{uri.path.split('/').find(&:present?)}"
      }.to_s
    end

    def identity_cookie_domain
      @identity_cookie_domain ||= if Rails.env.production?
                                    return ".#{base_domain}"
                                  else
                                    :all
                                  end
    end

    def base_domain
      @base_domain ||= begin
        domain = ENV["GOVUK_APP_DOMAIN"]

        unless /(http(s?):).*/.match(domain)
          domain = "https://#{domain}"
        end

        URI.parse(domain).host.sub("hub.", "")
      end
    end

    def revision
      @revision ||= `cat REVISION 2>/dev/null || echo 'development'`.strip
    end

    def environment
      ENV.fetch("ENVIRONMENT", "production")
    end

    def id_token_cookie_name
      cookie_name_for("id_token")
    end

    def refresh_token_cookie_name
      cookie_name_for("refresh_token")
    end

    def cookie_name_for(base_name)
      case environment
      when "production"
        base_name
      else
        "#{environment}_#{base_name}"
      end.to_sym
    end

    def uk_backend_url
      @uk_backend_url ||= ENV["UK_BACKEND_URL"]
    end

    def uk_backend_bearer_token
      @uk_backend_bearer_token ||= ENV["UK_BACKEND_BEARER_TOKEN"]
    end

    def admin_domain
      @admin_domain ||= ENV.fetch("ADMIN_DOMAIN", "transformuk.com")
    end

    def dev_bypass_auth_enabled?
      ENV.fetch("DEV_BYPASS_AUTH", "false") == "true"
    end

    def dev_bypass_user_password
      ENV.fetch("DEV_BYPASS_USER_PASSWORD", "dev")
    end

    def dev_bypass_admin_password
      ENV.fetch("DEV_BYPASS_ADMIN_PASSWORD", "admin")
    end
  end
end
