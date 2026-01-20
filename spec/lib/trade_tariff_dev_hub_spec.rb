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
      allow(Rails.env).to receive(:production?).and_return(true)
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
    around do |example|
      original_environment = ENV["ENVIRONMENT"]
      example.run
    ensure
      ENV["ENVIRONMENT"] = original_environment
    end

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
    around do |example|
      original_environment = ENV["ENVIRONMENT"]
      example.run
    ensure
      ENV["ENVIRONMENT"] = original_environment
    end

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
end
