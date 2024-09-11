data "aws_caller_identity" "current" {}
data "aws_lambda_layer_version" "github_layer" {
  layer_name = var.layer_name
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  function_source_dir = "./lambdas/functions/runner"
}

data "archive_file" "function_zip" {
  source_dir  = local.function_source_dir
  type        = "zip"
  output_path = "${local.function_source_dir}.zip"
}

resource "aws_lambda_function" "runner" {
  source_code_hash = data.archive_file.function_zip.output_base64sha256
  filename         = "${local.function_source_dir}.zip"
  description      = "runner for GH runner"
  function_name    = "${var.prefix}-${var.environment}-runner"
  role             = aws_iam_role.runner_lambda.arn
  handler          = var.runner_lambda_handler
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  architectures   = [var.lambda_architecture]


  environment {
    variables = {
      LOG_LEVEL   = var.log_level
      ENVIRONMENT = var.environment
      WEBHOOK_SECRET_PATH = var.github_app_webhook_secret.name
      GITHUB_APPID_PATH = var.github_app_id.name
      GITHUB_APP_PRIVATE_KEY_PATH = var.github_app_private_key.name
      ECS_CLUSTER = var.ecs_cluster_name
      CONTAINER_NAME = var.ecs_container_name
      TASK_DEFINITION = var.task_definition
      TASK_DEFINITION_ARN = var.task_definition_arn
      SUBNETS = var.subnet_ids
      SECURITY_GROUPS = var.security_groups

    }
  }

  layers = [data.aws_lambda_layer_version.github_layer.arn]

  tags = var.tags
}


resource "aws_cloudwatch_log_group" "runner" {
  name              = "/aws/lambda/${aws_lambda_function.runner.function_name}"
  retention_in_days = var.logging_retention_in_days
  kms_key_id        = var.logging_kms_key_id
  tags              = var.tags
}

resource "aws_lambda_permission" "runner" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.runner.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.webhook-api.execution_arn}/*/*/${local.webhook_endpoint}"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner_lambda" {
  name                 = "${var.prefix}-${var.environment}-lambda-role"
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume_role_policy.json
  permissions_boundary = var.role_permissions_boundary
  tags                 = var.tags
}

resource "aws_iam_role_policy" "runner_logging" {
  name = "${var.prefix}-${var.environment}-lambda-logging-policy"
  role = aws_iam_role.runner_lambda.name
  policy = templatefile("${path.module}/policies/lambda-cloudwatch.json", {
    log_group_arn = aws_cloudwatch_log_group.runner.arn
  })
}

resource "aws_iam_role_policy" "runner_ssm" {
  name = "${var.prefix}-${var.environment}-publish-ssm-policy"
  role = aws_iam_role.runner_lambda.name

  policy = templatefile("${path.module}/policies/lambda-ssm.json", {
    github_app_webhook_secret_arn = var.github_app_webhook_secret.arn,
    kms_key_arn                   = var.kms_key_arn != null ? var.kms_key_arn : ""
    github_app_id_arn             = var.github_app_id.arn,
    github_app_private_key_arn     = var.github_app_private_key.arn,
    gha_runner_image_name_arn     = var.gha_runner_image.arn
    lambda_role_ecs_task_permission = var.task_definition_arn
  })
}

resource "aws_iam_role_policy" "passing_role" {
  name = "${var.prefix}-${var.environment}-pass-role-to-ecstask-policy"
  role = aws_iam_role.runner_lambda.name

  policy = templatefile("${path.module}/policies/lambda-pass-role-policy.json", {
    account_id = local.account_id
  })
}