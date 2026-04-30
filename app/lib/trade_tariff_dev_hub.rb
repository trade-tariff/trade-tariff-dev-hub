module TradeTariffDevHub
  # Page size for Pagy-backed admin lists. Passed explicitly to `pagy(..., limit: ...)` so it
  # cannot silently fall back to Pagy’s built-in default (20 on Pagy 9).
  ADMIN_PAGY_PAGE_SIZE = 10

  # Name of the cookie that stores the user's analytics consent choice as JSON.
  # Must stay in sync with the meta tag emitted in app/views/layouts/application.html.erb
  # and the JS cookie banner in app/javascript/application.js.
  POLICY_COOKIE_NAME = "cookies_policy".freeze

  # Name of the cookie that tracks whether the user has dismissed the post-choice
  # confirmation banner ("You have accepted/rejected additional cookies").
  PREFERENCES_SET_COOKIE_NAME = "cookies_preferences_set".freeze

  # Cookie name prefixes set by Google Analytics / Google Tag Manager. When a user
  # revokes consent we clear any cookie whose name starts with one of these.
  ANALYTICS_COOKIE_PREFIXES = %w[_ga _gat _gid].freeze

  class << self
    def govuk_app_domain
      @govuk_app_domain ||= ENV.fetch(
        "GOVUK_APP_DOMAIN",
        "https://localhost:3004",
      )
    end

    def deletion_enabled?
      ENV.fetch("DELETION_ENABLED", "false") == "true"
    end

    def role_request_enabled?
      # Allow explicit override via environment variable
      return ENV["FEATURE_FLAG_ROLE_REQUEST"] == "true" if ENV.key?("FEATURE_FLAG_ROLE_REQUEST")

      # Default: enabled in development/test, disabled in production/staging
      Rails.env.development? || Rails.env.test?
    end

    # When true, new users without an invitation get a personal organisation at sign-in.
    # Production defaults to false (invitation-only). Staging, deployed development, and local
    # Rails development default to true. Set FEATURE_FLAG_SELF_SERVICE_ORG_CREATION explicitly
    # to override (e.g. false on staging, true on production during a pilot).
    def self_service_org_creation_enabled?
      if ENV.key?("FEATURE_FLAG_SELF_SERVICE_ORG_CREATION")
        return ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"] == "true"
      end

      return true if Rails.env.development?
      return true if %w[development staging].include?(environment)

      false
    end

    # Allowed purely based on the self-service org creation feature flag.
    # Production remains gated because self_service_org_creation_enabled? defaults to false there
    # unless FEATURE_FLAG_SELF_SERVICE_ORG_CREATION=true is set explicitly.
    def allow_passwordless_self_service_org_creation?
      self_service_org_creation_enabled?
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

    def google_tag_manager_container_id
      ENV.fetch("GOOGLE_TAG_MANAGER_CONTAINER_ID", "")
    end

    def analytics_cookie_delete_domains(host)
      return [] if host.blank?

      domains = [host, ".#{host}"]
      registrable_domain = host.split(".").last(2).join(".")
      domains << ".#{registrable_domain}" if registrable_domain.present?
      domains.uniq
    end

    def govuk_notifier_api_key
      @govuk_notifier_api_key ||= ENV["GOVUK_NOTIFY_API_KEY"]
    end

    def application_support_email
      @application_support_email ||= ENV["APPLICATION_SUPPORT_EMAIL"] || "dev@example.com"
    end

    # Optional: when set, used as fallback recipient(s) for role request notifications when no admin org exists.
    # In development you can set ROLE_REQUEST_NOTIFICATION_EMAIL to receive role requests without an admin organisation.
    def role_request_notification_email
      @role_request_notification_email ||= ENV["ROLE_REQUEST_NOTIFICATION_EMAIL"]
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

    # Base URL for the identity service client credentials API (POST/DELETE /api/client_credentials).
    def identity_client_credentials_api_url
      @identity_client_credentials_api_url ||= URI.join(identity_base_url, "api/").to_s
    end

    # Bearer token for identity service API (create/delete app client credentials). Required when provisioning Trade Tariff keys.
    def identity_api_key
      @identity_api_key ||= ENV["IDENTITY_API_KEY"]
    end

    # OAuth2 token endpoint where consumers exchange client_id + client_secret for an access token.
    # Set COGNITO_TOKEN_ENDPOINT explicitly, or it is derived from ENVIRONMENT (development/staging/production).
    # Outside deployed envs (e.g. test), falls back to development URL so tests do not hit production auth.
    def cognito_token_endpoint
      @cognito_token_endpoint ||= if ENV["COGNITO_TOKEN_ENDPOINT"].present?
                                    ENV["COGNITO_TOKEN_ENDPOINT"]
                                  else
                                    base = case environment
                                           when "development" then "https://auth.id.dev.trade-tariff.service.gov.uk"
                                           when "staging" then "https://auth.id.staging.trade-tariff.service.gov.uk"
                                           when "production" then "https://auth.id.trade-tariff.service.gov.uk"
                                           else "https://auth.id.dev.trade-tariff.service.gov.uk"
                                           end
                                    "#{base}/oauth2/token"
                                  end
    end

    # Pre-created API Gateway usage plan ID for Trade Tariff keys (from Terraform). Required when provisioning Trade Tariff keys.
    def trade_tariff_usage_plan_id
      @trade_tariff_usage_plan_id ||= ENV["TRADE_TARIFF_USAGE_PLAN_ID"]
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

    # Returns true for deployed environments (staging + production).
    # Uses ENVIRONMENT (not Rails.env) so that AWS development, where ENVIRONMENT=development
    # but RAILS_ENV may be production, is correctly treated as non-deployed.
    def deployed_environment?
      %w[production staging].include?(environment)
    end

    # True only for the live production slot (ENVIRONMENT=production). Not staging, dev, or test.
    def live_production_environment?
      environment == "production"
    end

    # Returns true for the deployed development environment in AWS.
    # This intentionally keys off ENVIRONMENT, not Rails.env.
    def development_deployment_environment?
      environment == "development"
    end

    # Restrict non-FPO/non-admin org sessions after identity callback in production only.
    def block_non_fpo_identity_sessions_in_production?
      environment == "production"
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
      @uk_backend_url ||= ENV.fetch("UK_BACKEND_URL", "https://backend-uk.tariff.internal:8443/uk/api")
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
