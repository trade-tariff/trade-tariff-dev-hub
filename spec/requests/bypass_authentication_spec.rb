# frozen_string_literal: true

RSpec.describe "Bypass authentication", type: :request do
  let(:identity_consumer_url) { "http://id.example.test/portal" }

  before do
    allow(Rails).to receive(:env).and_return("development".inquiry)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BYPASS_AUTHENTICATION").and_return(bypass_authentication)
    allow(TradeTariffDevHub).to receive(:identity_consumer_url).and_return(identity_consumer_url)
  end

  context "when BYPASS_AUTHENTICATION is true" do
    let(:bypass_authentication) { "true" }

    it "signs in as the dummy user without visiting Identity", :aggregate_failures do
      get api_keys_path
      expect(response).to redirect_to(auth_redirect_path)

      follow_redirect!
      dummy_user = User.find_by!(user_id: "dummy_user", email_address: "dummy@user.com")
      expect(dummy_user.organisation.organisation_name).to eq("Dummy Dev Org")
      expect(response).to redirect_to(organisation_path(dummy_user.organisation))

      get trade_tariff_keys_path
      expect(response).to have_http_status(:ok)

      get api_keys_path
      expect(response).to have_http_status(:ok)
    end
  end

  context "when BYPASS_AUTHENTICATION is unset" do
    let(:bypass_authentication) { nil }

    it "sends the user to Identity" do
      get api_keys_path
      expect(response).to redirect_to(identity_consumer_url)
    end
  end
end
