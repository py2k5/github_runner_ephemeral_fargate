
output "lambda" {
  value = aws_lambda_function.runner
}

output "role" {
  value = aws_iam_role.runner_lambda
}

output "api_invocation_url" {
  value = "${aws_api_gateway_stage.webhook-stage.invoke_url}/${local.webhook_endpoint}"
}
