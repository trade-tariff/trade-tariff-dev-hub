require "rails_helper"

RSpec.describe "Healthcheck", type: :request do
  describe "GET /healthcheck" do
    before do
      allow(TradeTariffDevHub).to receive(:revision).and_return("abc123")
    end

    it "returns the app revision as git_sha1", :aggregate_failures do
      get "/healthcheck"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("git_sha1" => "abc123")
    end
  end
end
