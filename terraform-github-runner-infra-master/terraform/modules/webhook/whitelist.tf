data "aws_api_gateway_rest_api" "webhook_api" {
  name =  "${var.prefix}-${var.environment}-${local.webhook_endpoint}"
  depends_on = [ aws_api_gateway_rest_api.webhook-api ]
}

# create lambda function
locals {
  whitelist_source_dir = "./lambdas/functions/ip_whitelist"
}

data "archive_file" "whitelist_function_zip" {
  source_dir  = local.whitelist_source_dir
  type        = "zip"
  output_path = "${local.whitelist_source_dir}.zip"
}

resource "aws_lambda_function" "ip_whitelist" {
  source_code_hash = data.archive_file.whitelist_function_zip.output_base64sha256
  filename         = "${local.whitelist_source_dir}.zip"
  description      = "IP whitelister for GH runner"
  function_name    = "${var.prefix}-${var.environment}-whitelister"
  role             = aws_iam_role.whitelist_lambda.arn
  handler          = "whitelist_github_ips.lambda_handler"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  architectures   = [var.lambda_architecture]


  environment {
    variables = {
        LOG_LEVEL   = var.log_level
        ENVIRONMENT = var.environment
        API_ID = data.aws_api_gateway_rest_api.webhook_api.id
    }
  }

  layers = [data.aws_lambda_layer_version.github_layer.arn]
  depends_on = [ aws_api_gateway_rest_api.webhook-api ]
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "whitelist" {
  name              = "/aws/lambda/${aws_lambda_function.ip_whitelist.function_name}"
  retention_in_days = var.logging_retention_in_days
  kms_key_id        = var.logging_kms_key_id
  tags              = var.tags
}


resource "aws_iam_role" "whitelist_lambda" {
  name                 = "${var.prefix}-${var.environment}-whitelist-role"
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags                 = var.tags
}

resource "aws_iam_role_policy" "whitelist_logging" {
  name = "${var.prefix}-${var.environment}-whitelist-lambda-logging-policy"
  role = aws_iam_role.whitelist_lambda.name
  policy = templatefile("${path.module}/policies/lambda-cloudwatch.json", {
    log_group_arn = aws_cloudwatch_log_group.whitelist.arn
  })
}

resource "aws_iam_role_policy" "whitelist_lambda" {
  name = "${var.prefix}-${var.environment}-whitelist-lambda-policy"
  role = aws_iam_role.whitelist_lambda.name
  policy = <<EOF
             {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "apigateway:GET",
                            "apigateway:PATCH",
                            "apigateway:UpdateRestApiPolicy"
                        ],
                        "Resource": "arn:aws:apigateway:ap-southeast-2::/restapis/${data.aws_api_gateway_rest_api.webhook_api.id}"
                    }
                ]
             }
EOF
}

#write eventbridge scheduler rule

resource "aws_scheduler_schedule" "whitelist_scheduler" {
  name       = "${var.prefix}-${var.environment}-whitelist-scheduler"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 5 * * ? *)" # 5AM AEST

  target {
    arn      = aws_lambda_function.ip_whitelist.arn
    role_arn = aws_iam_role.whitelist_scheduler.arn
  }
}

# create role for above scheduler rule
resource "aws_iam_role" "whitelist_scheduler" {
  name = "${var.prefix}-${var.environment}-whitelist-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "scheduler.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
# add permission to the role to invoke lambda
resource "aws_iam_policy" "whitelist_scheduler_policy" {
  name        = "${var.prefix}-${var.environment}-whitelist-scheduler-policy"
  description = "Policy to allow eventbridge to invoke lambda"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [ 
                    "lambda:InvokeFunction"
        ],
        Resource = aws_lambda_function.ip_whitelist.arn
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "scheduler_lambda_invoke_policy_attachment" {
  role       = aws_iam_role.whitelist_scheduler.name
  policy_arn = aws_iam_policy.whitelist_scheduler_policy.arn
}