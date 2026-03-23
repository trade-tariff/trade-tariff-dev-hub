# TESTING ONLY - remove before merge
resource "time_sleep" "cancel_test" {
  create_duration = "3m"
}

module "service" {
  source = "git@github.com:trade-tariff/trade-tariff-platform-terraform-modules.git//aws/ecs-service?ref=aws/ecs-service-v1.21.0"

  region = var.region

  service_name  = "dev-hub"
  service_count = var.service_count

  cluster_name    = "trade-tariff-cluster-${var.environment}"
  subnet_ids      = data.aws_subnets.private.ids
  security_groups = [data.aws_security_group.this.id]
  target_group_mappings = [
    {
      target_group_arn = data.aws_lb_target_group.this.arn
      container_port   = 8080
    },
    {
      target_group_arn = data.aws_lb_target_group.this_https.arn
      container_port   = 8443
    },
  ]
  cloudwatch_log_group_name = "platform-logs-${var.environment}"

  min_capacity = var.min_capacity
  max_capacity = var.max_capacity

  docker_image = "382373577178.dkr.ecr.eu-west-2.amazonaws.com/tariff-dev-hub-production"
  docker_tag   = var.docker_tag
  skip_destroy = true

  cpu    = var.cpu
  memory = var.memory

  execution_role_policy_arns = [aws_iam_policy.exec.arn]
  task_role_policy_arns      = [aws_iam_policy.task.arn]
  enable_ecs_exec            = true

  container_definition_kind = "db-backed"

  init_container_entrypoint = [""]
  init_container_command = [
    "/bin/sh",
    "-c",
    "bundle exec rails db:migrate"
  ]

  service_environment_config = local.devhub_service_env_vars

  sns_topic_arns = [data.aws_sns_topic.slack_topic.arn]
}
