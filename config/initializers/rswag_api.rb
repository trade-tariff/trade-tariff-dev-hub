# Tells rswag-api to serve spec files from the swagger directory (for example swagger/v1/openapi.json).
Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.join("swagger").to_s
end
