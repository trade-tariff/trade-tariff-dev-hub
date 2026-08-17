# frozen_string_literal: true

RSpec.describe TradeTariffDevHub do
  after do
    described_class.instance_variables.each do |name|
      described_class.remove_instance_variable(name)
    end
  end

  describe ".base_domain" do
    before do
      allow(ENV).to receive(:[]).with("GOVUK_APP_DOMAIN").and_return(govuk_app_domain)
    end

    context "when the GOVUK_APP_DOMAIN includes the scheme" do
      subject(:base_domain) { described_class.base_domain }

      let(:govuk_app_domain) { "https://hub.example.com" }

      it { is_expected.to eq("example.com") }
    end

    context "when the GOVUK_APP_DOMAIN does not include the scheme" do
      subject(:base_domain) { described_class.base_domain }

      let(:govuk_app_domain) { "hub.example.com" }

      it { is_expected.to eq("example.com") }
    end
  end

  describe ".identity_cookie_domain" do
    subject(:identity_cookie_domain) { described_class.identity_cookie_domain }

    before do
      # Clear memoization
      described_class.instance_variable_set(:@identity_cookie_domain, nil)
      described_class.instance_variable_set(:@base_domain, nil)
      described_class.instance_variable_set(:@govuk_app_domain, nil)

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(ENV).to receive(:fetch).with("GOVUK_APP_DOMAIN", anything).and_return(govuk_app_domain)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GOVUK_APP_DOMAIN").and_return(govuk_app_domain)
    end

    context "when the GOVUK_APP_DOMAIN includes the scheme" do
      let(:govuk_app_domain) { "https://hub.example.com" }

      it { is_expected.to eq(".example.com") }
    end

    context "when the GOVUK_APP_DOMAIN does not include the scheme" do
      let(:govuk_app_domain) { "hub.example.com" }

      it { is_expected.to eq(".example.com") }
    end
  end

  describe ".id_token_cookie_name" do
    include_context "with restored ENVIRONMENT"

    context "when environment is production" do
      before { ENV["ENVIRONMENT"] = "production" }

      it "returns :id_token" do
        expect(described_class.id_token_cookie_name).to eq(:id_token)
      end
    end

    context "when environment is staging" do
      before { ENV["ENVIRONMENT"] = "staging" }

      it "returns :staging_id_token" do
        expect(described_class.id_token_cookie_name).to eq(:staging_id_token)
      end
    end

    context "when environment is development" do
      before { ENV["ENVIRONMENT"] = "development" }

      it "returns :development_id_token" do
        expect(described_class.id_token_cookie_name).to eq(:development_id_token)
      end
    end
  end

  describe ".refresh_token_cookie_name" do
    include_context "with restored ENVIRONMENT"

    context "when environment is production" do
      before { ENV["ENVIRONMENT"] = "production" }

      it "returns :refresh_token" do
        expect(described_class.refresh_token_cookie_name).to eq(:refresh_token)
      end
    end

    context "when environment is staging" do
      before { ENV["ENVIRONMENT"] = "staging" }

      it "returns :staging_refresh_token" do
        expect(described_class.refresh_token_cookie_name).to eq(:staging_refresh_token)
      end
    end

    context "when environment is development" do
      before { ENV["ENVIRONMENT"] = "development" }

      it "returns :development_refresh_token" do
        expect(described_class.refresh_token_cookie_name).to eq(:development_refresh_token)
      end
    end
  end

  describe ".self_service_org_creation_enabled?" do
    include_context "with restored ENVIRONMENT and self-service org creation flag"

    before do
      allow(Rails.env).to receive(:development?).and_return(false)
    end

    context "when FEATURE_FLAG_SELF_SERVICE_ORG_CREATION is true" do
      before do
        ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"] = "true"
        ENV["ENVIRONMENT"] = "production"
      end

      it { expect(described_class.self_service_org_creation_enabled?).to be true }
    end

    context "when FEATURE_FLAG_SELF_SERVICE_ORG_CREATION is false" do
      before do
        ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"] = "false"
        ENV["ENVIRONMENT"] = "staging"
      end

      it { expect(described_class.self_service_org_creation_enabled?).to be false }
    end

    context "when the flag is unset and ENVIRONMENT is production" do
      before do
        ENV.delete("FEATURE_FLAG_SELF_SERVICE_ORG_CREATION")
        ENV["ENVIRONMENT"] = "production"
      end

      it { expect(described_class.self_service_org_creation_enabled?).to be false }
    end

    context "when the flag is unset and ENVIRONMENT is staging" do
      before do
        ENV.delete("FEATURE_FLAG_SELF_SERVICE_ORG_CREATION")
        ENV["ENVIRONMENT"] = "staging"
      end

      it { expect(described_class.self_service_org_creation_enabled?).to be true }
    end

    context "when the flag is unset and Rails.env.development? is true" do
      before do
        ENV.delete("FEATURE_FLAG_SELF_SERVICE_ORG_CREATION")
        ENV["ENVIRONMENT"] = "production"
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it { expect(described_class.self_service_org_creation_enabled?).to be true }
    end
  end

  describe ".allow_passwordless_self_service_org_creation?" do
    include_context "with restored ENVIRONMENT and self-service org creation flag"

    before do
      allow(Rails.env).to receive(:development?).and_return(false)
    end

    it "returns false when self-service is not enabled" do
      ENV["ENVIRONMENT"] = "staging"
      ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"] = "false"

      expect(described_class.allow_passwordless_self_service_org_creation?).to be(false)
    end

    it "returns true in staging when self-service is enabled" do
      ENV["ENVIRONMENT"] = "staging"
      ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"] = "true"

      expect(described_class.allow_passwordless_self_service_org_creation?).to be(true)
    end

    it "returns false in production when the self-service flag is unset" do
      ENV["ENVIRONMENT"] = "production"
      ENV.delete("FEATURE_FLAG_SELF_SERVICE_ORG_CREATION")

      expect(described_class.allow_passwordless_self_service_org_creation?).to be(false)
    end

    it "returns true in production when the self-service flag is enabled" do
      ENV["ENVIRONMENT"] = "production"
      ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"] = "true"

      expect(described_class.allow_passwordless_self_service_org_creation?).to be(true)
    end
  end

  describe ".block_non_fpo_identity_sessions_in_production?" do
    include_context "with restored ENVIRONMENT"

    it "returns true in production" do
      ENV["ENVIRONMENT"] = "production"

      expect(described_class.block_non_fpo_identity_sessions_in_production?).to be(true)
    end

    it "returns false in staging" do
      ENV["ENVIRONMENT"] = "staging"

      expect(described_class.block_non_fpo_identity_sessions_in_production?).to be(false)
    end
  end

  describe ".google_tag_manager_container_id" do
    before do
      allow(ENV).to receive(:fetch).and_call_original
    end

    it "returns the GOOGLE_TAG_MANAGER_CONTAINER_ID env var when set" do
      allow(ENV).to receive(:fetch).with("GOOGLE_TAG_MANAGER_CONTAINER_ID", "").and_return("GTM-KPM7NRDG")

      expect(described_class.google_tag_manager_container_id).to eq("GTM-KPM7NRDG")
    end

    it "returns a blank string when GOOGLE_TAG_MANAGER_CONTAINER_ID is unset" do
      allow(ENV).to receive(:fetch).with("GOOGLE_TAG_MANAGER_CONTAINER_ID", "").and_return("")

      expect(described_class.google_tag_manager_container_id).to eq("")
    end
  end

  describe ".analytics_cookie_delete_domains" do
    it "returns host and domain variants for deleting analytics cookies" do
      expect(described_class.analytics_cookie_delete_domains("hub.dev.trade-tariff.service.gov.uk")).to eq(
        [
          "hub.dev.trade-tariff.service.gov.uk",
          ".hub.dev.trade-tariff.service.gov.uk",
          ".gov.uk",
        ],
      )
    end

    it "returns an empty array when host is blank" do
      expect(described_class.analytics_cookie_delete_domains(nil)).to eq([])
    end
  end

  describe ".live_production_environment?" do
    include_context "with restored ENVIRONMENT"

    it "returns true when ENVIRONMENT is production" do
      ENV["ENVIRONMENT"] = "production"

      expect(described_class.live_production_environment?).to be(true)
    end

    it "returns false when ENVIRONMENT is staging" do
      ENV["ENVIRONMENT"] = "staging"

      expect(described_class.live_production_environment?).to be(false)
    end

    it "returns false when ENVIRONMENT is test" do
      ENV["ENVIRONMENT"] = "test"

      expect(described_class.live_production_environment?).to be(false)
    end
  end

  {
    enquiry_form_url: ["ENQUIRY_FORM_URL", "https://example.com/enquiries"],
    govuk_app_domain: ["GOVUK_APP_DOMAIN", "https://hub.example.com"],
    documentation_url: ["DOCUMENTATION_URL", "https://example.com/docs"],
    feedback_url: ["FEEDBACK_URL", "https://example.com/feedback"],
    terms_and_conditions_url: ["TERMS_AND_CONDITIONS_URL", "https://example.com/terms"],
    govuk_notifier_api_key: %w[GOVUK_NOTIFY_API_KEY notify-key],
    application_support_email: ["APPLICATION_SUPPORT_EMAIL", "support@example.com"],
    role_request_notification_email: ["ROLE_REQUEST_NOTIFICATION_EMAIL", "roles@example.com"],
    identity_encryption_secret: %w[IDENTITY_ENCRYPTION_SECRET secret],
    identity_api_key: %w[IDENTITY_API_KEY identity-key],
    trade_tariff_usage_plan_id: %w[TRADE_TARIFF_USAGE_PLAN_ID usage-plan],
    identity_cognito_jwks_url: ["IDENTITY_COGNITO_JWKS_URL", "https://identity.example.com/pool/.well-known/jwks.json"],
    uk_backend_url: ["UK_BACKEND_URL", "https://backend.example.com/uk/api"],
    uk_backend_bearer_token: %w[UK_BACKEND_BEARER_TOKEN backend-token],
    admin_domain: ["ADMIN_DOMAIN", "example.com"],
  }.each do |method_name, (environment_name, value)|
    describe ".#{method_name}" do
      around do |example|
        original_value = ENV[environment_name]
        ENV[environment_name] = value
        example.run
      ensure
        original_value.nil? ? ENV.delete(environment_name) : ENV[environment_name] = original_value
      end

      it "returns the configured value" do
        expect(described_class.public_send(method_name)).to eq(value)
      end
    end
  end

  describe ".role_request_enabled?" do
    it "uses the explicit feature flag when set" do
      allow(ENV).to receive(:key?).with("FEATURE_FLAG_ROLE_REQUEST").and_return(true)
      allow(ENV).to receive(:[]).with("FEATURE_FLAG_ROLE_REQUEST").and_return("true")

      expect(described_class.role_request_enabled?).to be(true)
    end

    it "defaults to enabled in test" do
      allow(ENV).to receive(:key?).with("FEATURE_FLAG_ROLE_REQUEST").and_return(false)

      expect(described_class.role_request_enabled?).to be(true)
    end
  end

  describe "identity URLs" do
    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("IDENTITY_BASE_URL", anything).and_return("https://identity.example.com/")
      allow(ENV).to receive(:fetch).with("IDENTITY_CONSUMER", anything).and_return("portal")
    end

    it "builds the consumer URL" do
      expect(described_class.identity_consumer_url).to eq("https://identity.example.com/portal")
    end

    it "builds the client credentials API URL" do
      expect(described_class.identity_client_credentials_api_url).to eq("https://identity.example.com/api/")
    end
  end

  describe ".cognito_token_endpoint" do
    include_context "with restored ENVIRONMENT"

    it "returns an explicitly configured endpoint" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("COGNITO_TOKEN_ENDPOINT").and_return("https://auth.example.com/token")

      expect(described_class.cognito_token_endpoint).to eq("https://auth.example.com/token")
    end

    {
      "development" => "https://auth.id.dev.trade-tariff.service.gov.uk/oauth2/token",
      "staging" => "https://auth.id.staging.trade-tariff.service.gov.uk/oauth2/token",
      "production" => "https://auth.id.trade-tariff.service.gov.uk/oauth2/token",
      "test" => "https://auth.id.dev.trade-tariff.service.gov.uk/oauth2/token",
    }.each do |environment, endpoint|
      it "returns the #{environment} endpoint" do
        ENV["ENVIRONMENT"] = environment
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("COGNITO_TOKEN_ENDPOINT").and_return(nil)

        expect(described_class.cognito_token_endpoint).to eq(endpoint)
      end
    end
  end

  describe ".identity_cognito_jwks_keys" do
    let(:jwks_url) { "https://identity.example.com/pool/.well-known/jwks.json" }

    before do
      allow(described_class).to receive(:identity_cognito_jwks_url).and_return(jwks_url)
      allow(Rails.cache).to receive(:fetch).and_yield
    end

    it "returns nil when the JWKS URL is blank" do
      allow(described_class).to receive(:identity_cognito_jwks_url).and_return(nil)

      expect(described_class.identity_cognito_jwks_keys).to be_nil
    end

    it "returns keys from a successful response" do
      response = instance_double(Faraday::Response, success?: true, body: '{"keys":[{"kid":"key-id"}]}')
      allow(Faraday).to receive(:get).and_return(response)

      expect(described_class.identity_cognito_jwks_keys).to eq([{ "kid" => "key-id" }])
    end

    it "returns nil from an unsuccessful response" do
      response = instance_double(Faraday::Response, success?: false, status: 503, body: "Unavailable")
      allow(Faraday).to receive(:get).and_return(response)

      expect(described_class.identity_cognito_jwks_keys).to be_nil
    end

    {
      Faraday::ConnectionFailed => "connection failed",
      Faraday::TimeoutError => "request timed out",
      Faraday::ClientError => "client error",
      Faraday::ServerError => "server error",
      RuntimeError => "unexpected error",
    }.each do |error_class, description|
      it "returns nil when there is a #{description}" do
        allow(Faraday).to receive(:get).and_raise(error_class.new(description))

        expect(described_class.identity_cognito_jwks_keys).to be_nil
      end
    end

    it "returns nil when the response is not valid JSON" do
      response = instance_double(Faraday::Response, success?: true, body: "invalid")
      allow(Faraday).to receive(:get).and_return(response)

      expect(described_class.identity_cognito_jwks_keys).to be_nil
    end
  end

  describe ".identity_cognito_issuer_url" do
    it "returns the user pool URL" do
      allow(described_class).to receive(:identity_cognito_jwks_url).and_return("https://identity.example.com/pool/.well-known/jwks.json")

      expect(described_class.identity_cognito_issuer_url).to eq("https://identity.example.com/pool")
    end
  end

  describe "remaining environment helpers" do
    include_context "with restored ENVIRONMENT"

    it "uses the non-production cookie domain" do
      allow(Rails.env).to receive(:production?).and_return(false)

      expect(described_class.identity_cookie_domain).to eq(:all)
    end

    it "returns the application revision" do
      expect(described_class.revision).to be_present
    end

    it "identifies a deployed environment" do
      ENV["ENVIRONMENT"] = "staging"

      expect(described_class.deployed_environment?).to be(true)
    end
  end
end
