require "swagger_helper"
# This define API contract metadata (path, tags, produces, schema, responses) so rswag can generate openapi.json.
# Used for API documentation generation (and contract validation).

RSpec.describe "Healthcheck API", type: :request do
  path "/healthcheck" do
    get "Returns the app revision" do
      tags "Healthcheck"
      produces "application/json"

      response "200", "healthcheck response" do
        schema type: :object,
          properties: {
            git_sha1: { type: :string },
          },
          required: ["git_sha1"]

        before do
          allow(TradeTariffDevHub).to receive(:revision).and_return("abc123")
        end

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq("git_sha1" => "abc123")
        end
      end
    end
  end
end
