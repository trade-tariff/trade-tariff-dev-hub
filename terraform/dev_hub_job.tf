# ECS job for scheduled tasks (e.g. daily API key cleanup). Development only.
# EventBridge triggers the job with a command override to run the rake task.

module "dev-hub-job" {
  source = "git@github.com:trade-tariff/trade-tariff-platform-terraform-modules.git//aws/ecs-service?ref=aws/ecs-service-v1.19.2"
  count  = var.environment == "development" ? 1 : 0

  region = var.region

  service_name              = "dev-hub-job"
  container_definition_kind = "job"
  container_command         = ["/bin/sh", "-c", "bin/null-service"]
  service_count             = 0

  cluster_name              = "trade-tariff-cluster-${var.environment}"
  subnet_ids                = data.aws_subnets.private.ids
  security_groups           = [data.aws_security_group.this.id]
  cloudwatch_log_group_name = "platform-logs-${var.environment}"

  docker_image = "382373577178.dkr.ecr.eu-west-2.amazonaws.com/tariff-dev-hub-production"
  docker_tag   = var.docker_tag
  cpu          = var.cpu
  memory       = var.memory

  task_role_policy_arns      = [aws_iam_policy.task.arn]
  execution_role_policy_arns = [aws_iam_policy.exec.arn]
  service_environment_config = local.job_secret_env_vars
  enable_ecs_exec            = true
  has_autoscaler             = false
  max_capacity               = 1
  min_capacity               = 0
  sns_topic_arns             = [data.aws_sns_topic.slack_topic.arn]
}

data "aws_ecs_task_definition" "job" {
  count = var.environment == "development" ? 1 : 0

  task_definition = "dev-hub-job-${local.account_id}"
  depends_on      = [module.dev-hub-job]
}

resource "aws_cloudwatch_event_rule" "dev_hub_cleanup" {
  count = var.environment == "development" ? 1 : 0

  name                = "dev-hub-daily-cleanup-${var.environment}"
  description         = "Triggers daily API key cleanup for dev-hub"
  schedule_expression = "cron(0 3 * * ? *)"
}

resource "aws_cloudwatch_event_target" "dev_hub_cleanup" {
  count = var.environment == "development" ? 1 : 0

  rule     = aws_cloudwatch_event_rule.dev_hub_cleanup[0].name
  arn      = data.aws_ecs_cluster.this.arn
  role_arn = aws_iam_role.eventbridge_ecs[0].arn

  input = jsonencode({
    containerOverrides = [{
      name    = "dev-hub-job"
      command = ["/bin/sh", "-c", "bundle exec rails cleanup:api_keys"]
    }]
  })

  ecs_target {
    task_count          = 1
    task_definition_arn = data.aws_ecs_task_definition.job[0].arn
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = data.aws_subnets.private.ids
      security_groups  = [data.aws_security_group.this.id]
      assign_public_ip = false
    }
  }
}

data "aws_iam_policy_document" "eventbridge_assume_role" {
  count = var.environment == "development" ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eventbridge_ecs" {
  count = var.environment == "development" ? 1 : 0

  name               = "dev-hub-eventbridge-ecs-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "eventbridge_run_task" {
  count = var.environment == "development" ? 1 : 0

  role       = aws_iam_role.eventbridge_ecs[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

data "aws_iam_policy_document" "eventbridge_pass_role" {
  count = var.environment == "development" ? 1 : 0

  statement {
    actions = ["iam:PassRole"]
    resources = [
      module.dev-hub-job[0].task_execution_role_arn,
      module.dev-hub-job[0].task_role_arn,
    ]
  }
}

resource "aws_iam_policy" "eventbridge_pass_role" {
  count = var.environment == "development" ? 1 : 0

  name   = "dev-hub-eventbridge-pass-role-${var.environment}"
  policy = data.aws_iam_policy_document.eventbridge_pass_role[0].json
}

resource "aws_iam_role_policy_attachment" "eventbridge_pass_role" {
  count = var.environment == "development" ? 1 : 0

  role       = aws_iam_role.eventbridge_ecs[0].name
  policy_arn = aws_iam_policy.eventbridge_pass_role[0].arn
}
