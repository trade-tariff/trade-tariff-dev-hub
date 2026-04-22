require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /cookies" do
    it "renders the cookies page", :aggregate_failures do
      get "/cookies"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cookies on the UK Trade Tariff Developer Portal")
      expect(response.body).to include("Cookies that measure website use")
    end
  end

  describe "GET /cookies-policy" do
    it "renders the cookie settings form", :aggregate_failures do
      get "/cookies-policy"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Change your cookie settings")
    end
  end

  describe "POST /cookies-policy" do
    it "stores the usage:true choice when accepted", :aggregate_failures do
      post "/cookies-policy", params: { usage: "true" }

      expect(response).to redirect_to(cookies_policy_path)
      expect(response.cookies["cookies_policy"]).to include("\"usage\":true")
    end

    it "stores the usage:false choice when rejected", :aggregate_failures do
      post "/cookies-policy", params: { usage: "false" }

      expect(response).to redirect_to(cookies_policy_path)
      expect(response.cookies["cookies_policy"]).to include("\"usage\":false")
    end

    it "rejects unexpected usage values and does not set consent cookie", :aggregate_failures do
      post "/cookies-policy", params: { usage: "yes-please" }

      expect(response).to redirect_to(cookies_policy_path)
      expect(flash[:alert]).to eq("Select whether to allow cookies that measure website use")
      expect(response.cookies["cookies_policy"]).to be_nil
    end

    it "rejects missing usage values and does not set consent cookie", :aggregate_failures do
      post "/cookies-policy", params: {}

      expect(response).to redirect_to(cookies_policy_path)
      expect(flash[:alert]).to eq("Select whether to allow cookies that measure website use")
      expect(response.cookies["cookies_policy"]).to be_nil
    end

    # The cookies_policy cookie must be readable by application.js so the banner can
    # reflect the user's current choice. Asserting on Set-Cookie attributes guards
    # against a future regression that silently adds HttpOnly (which would break the JS).
    it "sets SameSite=Lax and does not set HttpOnly on the cookies_policy cookie", :aggregate_failures do
      post "/cookies-policy", params: { usage: "true" }

      set_cookie_headers = Array(response.headers["Set-Cookie"]).flat_map { |h| h.split("\n") }
      policy_header = set_cookie_headers.find { |h| h.start_with?("#{TradeTariffDevHub::POLICY_COOKIE_NAME}=") }

      expect(policy_header).to be_present
      expect(policy_header).to match(/;\s*SameSite=lax/i)
      expect(policy_header).not_to match(/;\s*HttpOnly/i)
    end
  end

  describe "GTM rendering in application layout" do
    before do
      allow(TradeTariffDevHub).to receive(:google_tag_manager_container_id).and_return("GTM-KPM7NRDG")
    end

    context "when no cookies_policy cookie is set" do
      it "does not render the GTM snippet" do
        get "/cookies"

        expect(response.body).not_to include("googletagmanager.com")
      end
    end

    context "when cookies_policy has usage:false" do
      before do
        cookies["cookies_policy"] = { usage: false, remember_settings: true }.to_json
      end

      it "does not render the GTM snippet" do
        get "/cookies"

        expect(response.body).not_to include("googletagmanager.com")
      end
    end

    context "when cookies_policy has usage:true" do
      before do
        cookies["cookies_policy"] = { usage: true, remember_settings: true }.to_json
      end

      it "renders the GTM head script and the noscript iframe", :aggregate_failures do
        get "/cookies"

        expect(response.body).to include("googletagmanager.com/gtm.js")
        expect(response.body).to include("googletagmanager.com/ns.html?id=GTM-KPM7NRDG")
      end
    end

    context "when GTM container id is blank" do
      before do
        allow(TradeTariffDevHub).to receive(:google_tag_manager_container_id).and_return("")
        cookies["cookies_policy"] = { usage: true, remember_settings: true }.to_json
      end

      it "does not render the GTM snippet even with consent" do
        get "/cookies"

        expect(response.body).not_to include("googletagmanager.com")
      end
    end
  end
end
