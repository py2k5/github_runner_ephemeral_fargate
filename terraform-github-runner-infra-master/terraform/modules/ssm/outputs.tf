output "parameters" {
  value = {
    github_app_id = {
      name = aws_ssm_parameter.github_app_id_ssm.name
      arn  = aws_ssm_parameter.github_app_id_ssm.arn
    }
    github_app_private_key = {
      name = aws_ssm_parameter.github_app_private_key_ssm.name
      arn  = aws_ssm_parameter.github_app_private_key_ssm.arn
    }
    github_app_webhook_secret = {
      name = aws_ssm_parameter.github_app_webhook_secret_ssm.name
      arn  = aws_ssm_parameter.github_app_webhook_secret_ssm.arn
    }
    gha_runner_image = {
      name = aws_ssm_parameter.gha_runner_image_ssm.name
      arn  = aws_ssm_parameter.gha_runner_image_ssm.arn
    }
  }
}