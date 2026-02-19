data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  tags = { Name = "trade-tariff-${var.environment}-vpc" }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Name = "*private*"
  }
}

data "aws_lb_target_group" "this" {
  name = "hub"
}

data "aws_security_group" "this" {
  name = "trade-tariff-ecs-security-group-${var.environment}"
}

data "aws_kms_key" "this" {
  key_id = "alias/secretsmanager-key"
}

data "aws_secretsmanager_secret" "this" {
  name = "dev-hub-configuration"
}

data "aws_secretsmanager_secret_version" "this" {
  secret_id = data.aws_secretsmanager_secret.this.id
}

data "aws_secretsmanager_secret" "ecs_tls_certificate" {
  name = "ecs-tls-certificate"
}

data "aws_sns_topic" "slack_topic" {
  name = "slack-topic"
}

data "aws_ecs_cluster" "this" {
  cluster_name = "trade-tariff-cluster-${var.environment}"
}

data "aws_secretsmanager_secret" "job" {
  count = var.environment == "development" ? 1 : 0

  name = "dev-hub-job-configuration"
}

data "aws_secretsmanager_secret_version" "job" {
  count = var.environment == "development" ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.job[0].id
}
