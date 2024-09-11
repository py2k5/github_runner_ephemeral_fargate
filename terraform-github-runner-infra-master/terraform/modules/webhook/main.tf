locals {
  webhook_endpoint = "webhook"
}

resource "aws_api_gateway_account" "all" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "api_gateway_logging" {
  name        = "api-gateway-logging"
  path        = "/"
  description = "IAM policy for logging from the api gateway"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "gateway_logs" {
  role       = aws_iam_role.cloudwatch.id
  policy_arn = aws_iam_policy.api_gateway_logging.arn
}

resource "aws_api_gateway_rest_api" "webhook-api" {
  name          = "${var.prefix}-${var.environment}-${local.webhook_endpoint}"
  tags          = var.tags
}

resource "aws_api_gateway_resource" "webhook-resource" {
  parent_id   = aws_api_gateway_rest_api.webhook-api.root_resource_id
  path_part   = "webhook"
  rest_api_id = aws_api_gateway_rest_api.webhook-api.id
}

resource "aws_api_gateway_method" "webhook-method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.webhook-resource.id
  rest_api_id   = aws_api_gateway_rest_api.webhook-api.id
}

resource "aws_api_gateway_integration" "webhook-integration" {
  http_method             = aws_api_gateway_method.webhook-method.http_method
  integration_http_method = "POST"
  resource_id              = aws_api_gateway_resource.webhook-resource.id
  rest_api_id              = aws_api_gateway_rest_api.webhook-api.id
  type                     = "AWS_PROXY"
  uri                      = aws_lambda_function.runner.invoke_arn
}

resource "aws_api_gateway_deployment" "webhook-deployment" {
  rest_api_id = aws_api_gateway_rest_api.webhook-api.id
  # depends_on = [ aws_api_gateway_integration.webhook-integration, aws_api_gateway_method.webhook-method, aws_api_gateway_resource.webhook-resource, aws_api_gateway_rest_api.webhook-api ]
  triggers = {
     redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook-resource.id,
      aws_api_gateway_method.webhook-method.id,
      aws_api_gateway_integration.webhook-integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "webhook-stage" {
  deployment_id = aws_api_gateway_deployment.webhook-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.webhook-api.id
  stage_name    = var.environment
  tags          = var.tags
  depends_on = [ aws_api_gateway_account.all ]
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.webhook-api.id
  stage_name  = aws_api_gateway_stage.webhook-stage.stage_name
  method_path = "*/*"
  
  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
  depends_on = [ aws_api_gateway_account.all ]
}

resource "aws_cloudwatch_log_group" "webhook-log" {
  name  = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.webhook-api.id}/${var.environment}"
  retention_in_days = 180
}



#add api-gateway resource policy
resource "aws_api_gateway_rest_api_policy" "webhook-resource-policy" {
  rest_api_id = aws_api_gateway_rest_api.webhook-api.id
  #read policy from file
  policy = templatefile("${path.module}/policies/api-gateway-resource-policy.json", {
    apigatewaysourcearn = "${aws_api_gateway_stage.webhook-stage.execution_arn}/POST/${local.webhook_endpoint}"
  })

}