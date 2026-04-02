# frozen_string_literal: true

RSpec.describe TradeTariffDevHub do
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

    it "returns false in production even when self-service flag is enabled" do
      ENV["ENVIRONMENT"] = "production"
      ENV["FEATURE_FLAG_SELF_SERVICE_ORG_CREATION"] = "true"

      expect(described_class.allow_passwordless_self_service_org_creation?).to be(false)
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

  describe ".development_deployment_environment?" do
    include_context "with restored ENVIRONMENT"

    it "returns true when ENVIRONMENT is development" do
      ENV["ENVIRONMENT"] = "development"

      expect(described_class.development_deployment_environment?).to be(true)
    end

    it "returns false when ENVIRONMENT is staging" do
      ENV["ENVIRONMENT"] = "staging"

      expect(described_class.development_deployment_environment?).to be(false)
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
end
