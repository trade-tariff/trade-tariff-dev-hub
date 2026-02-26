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

  tls_secret = jsondecode(data.aws_secretsmanager_secret_version.ecs_tls_certificate.secret_string)

  ecs_tls_env_vars = [
    {
      name  = "SSL_KEY_PEM"
      value = local.tls_secret.private_key
    },
    {
      name  = "SSL_CERT_PEM"
      value = local.tls_secret.certificate
    },
    {
      name  = "SSL_PORT"
      value = "8443"
    }
  ]

  devhub_service_env_vars = concat(local.secret_env_vars, local.ecs_tls_env_vars)

  job_secret_value = var.environment == "development" ? try(data.aws_secretsmanager_secret_version.job[0].secret_string, "{}") : "{}"
  job_secret_map   = jsondecode(local.job_secret_value)
  job_secret_env_vars = var.environment == "development" ? [
    for key, value in local.job_secret_map : {
      name  = key
      value = value
    }
  ] : []
}
