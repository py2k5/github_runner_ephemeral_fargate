locals {
  kms_key_arn   = var.kms_key_arn == null ? "alias/aws/ssm" : var.kms_key_arn
  default_value = "changeme"
  # app_id_parameter_exists = aws_ssm_parameter.github_app_id_ssm[0].name != null ? true : false
  # app_key_base64_parameter_exists = aws_ssm_parameter.github_app_private_key_ssm[0].name != null ? true : false
  # webhook_secret_parameter_exists = aws_ssm_parameter.github_app_webhook_secret_ssm[0].name != null ? true : false
  # gha_runner_image_parameter_exists = aws_ssm_parameter.gha_runner_image_ssm.name != null ? true : false
}