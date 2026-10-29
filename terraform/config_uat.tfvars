region             = "eu-west-2"
environment        = "uat"
enable_cleanup_job = false
cpu                = 1024
memory             = 2048
service_count      = 1
min_capacity       = 1
max_capacity       = 2

# The common stack creates these values again on each UAT start (RFC 002 in
# trade-tariff-platform-aws-terraform, "Generated values").
generated_secrets = {
  DATABASE_URL = "postgresdeveloperhub-connection-string"
}

generated_parameters = {
  REST_API_ID                = "/uat/REST_API_ID"
  TRADE_TARIFF_USAGE_PLAN_ID = "/uat/TRADE_TARIFF_USAGE_PLAN_ID"
}
