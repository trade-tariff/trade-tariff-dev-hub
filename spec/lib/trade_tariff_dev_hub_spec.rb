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
end
