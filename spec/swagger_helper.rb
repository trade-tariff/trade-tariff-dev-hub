require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  config.extend Rswag::Specs::ExampleGroupHelpers, type: :request
  config.include Rswag::Specs::ExampleHelpers, type: :request

  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/openapi.json" => {
      openapi: "3.0.1",
      info: {
        title: "Trade Tariff Dev Hub API",
        version: "v1",
      },
      servers: [
        {
          url: "{defaultHost}",
          variables: {
            defaultHost: {
              default: "http://localhost:#{ENV.fetch('PORT', 3000)}",
            },
          },
        },
      ],
    },
  }

  config.openapi_format = :json
end
