# frozen_string_literal: true

RSpec.describe "Errors", type: :request do
  {
    "/400" => [:bad_request, "The request you made is not valid"],
    "/404" => [:not_found, "Page not found"],
    "/405" => [:method_not_allowed, "Method not allowed"],
    "/406" => [:not_acceptable, "Not acceptable"],
    "/422" => [:unprocessable_content, "Unprocessable content"],
    "/429" => [:too_many_requests, "Too many requests"],
    "/500" => [:internal_server_error, "We are experiencing technical difficulties"],
    "/501" => [:not_implemented, "Not implemented"],
    "/503" => [:service_unavailable, "Maintenance mode"],
  }.each do |path, (status, message)|
    it "renders #{path} as HTML", :aggregate_failures do
      get path

      expect(response).to have_http_status(status)
      expect(response.body).to include(message)
    end
  end

  it "renders a JSON error", :aggregate_failures do
    get "/404", headers: { "Accept" => "application/json" }

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body).to eq("error" => "Resource not found")
  end

  it "renders an unsupported format as plain text", :aggregate_failures do
    get "/404", headers: { "Accept" => "application/xml" }

    expect(response).to have_http_status(:not_found)
    expect(response.body).to eq("Resource not found")
  end
end
