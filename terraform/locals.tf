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
}
