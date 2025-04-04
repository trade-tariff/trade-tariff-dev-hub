require 'rails_helper'

RSpec.describe "ApiKeys", type: :request do
  describe "GET /index" do
    api_keys = ApiKey.all

    it "returns a list of api keys" do
      get "/dashboard"
      expect(response).to be_successful
    end
  end
end
