data "aws_iam_policy_document" "task" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${local.account_id}:table/Organisations",
      "arn:aws:dynamodb:${var.region}:${local.account_id}:table/Users",
      "arn:aws:dynamodb:${var.region}:${local.account_id}:table/CustomerApiKeys"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "apigateway:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "task" {
  name   = "dev-hub-tasks-role-policy"
  policy = data.aws_iam_policy_document.task.json
}

data "aws_iam_policy_document" "exec" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [data.aws_secretsmanager_secret.this.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlainText",
      "kms:GenerateDataKeyWithoutPlaintext"
    ]
    resources = [data.aws_kms_key.this.arn]
  }
}

resource "aws_iam_policy" "exec" {
  name   = "dev-hub-execs-role-policy"
  policy = data.aws_iam_policy_document.exec.json
}
