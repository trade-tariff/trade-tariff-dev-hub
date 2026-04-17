# Configures the Swagger UI page and which spec it should load.
Rswag::Ui.configure do |c|
  c.openapi_endpoint "/api-docs/v1/openapi.json", "API V1 Docs"
end
