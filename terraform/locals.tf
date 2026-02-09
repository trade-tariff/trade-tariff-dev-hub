locals {
  account_id   = data.aws_caller_identity.current.account_id
  secret_map   = jsondecode(local.secret_value)
  secret_value = try(data.aws_secretsmanager_secret_version.this.secret_string, "{}")
  secret_env_vars = [
    for key, value in local.secret_map : {
      name  = key
      value = value
    }
  ]
  job_secret_value = var.environment == "development" ? try(data.aws_secretsmanager_secret_version.job[0].secret_string, "{}") : "{}"
  job_secret_map   = jsondecode(local.job_secret_value)
  job_secret_env_vars = var.environment == "development" ? [
    for key, value in local.job_secret_map : {
      name  = key
      value = value
    }
  ] : []
}
