# frozen_string_literal: true

RSpec.describe "Removed user verification paths", type: :request do
  %w[
    /user_verification/steps
    /user_verification/steps/1
    /user_verification/steps/completed
    /user_verification/steps/rejected
    /user_verification/completed
  ].each do |path|
    it "renders #{path} as not found", :aggregate_failures do
      get path

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
    end
  end
end
