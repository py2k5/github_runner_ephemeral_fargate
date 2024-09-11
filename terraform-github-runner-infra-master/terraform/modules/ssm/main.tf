 

resource "aws_ssm_parameter" "github_app_id_ssm" {
  name   = "/${var.ssm_param_prefix}/${var.prefix}/${var.environment}/github_app_id"
  type   = "SecureString"
  value  = var.github_app.id
  key_id = local.kms_key_arn
  tags   = var.tags
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "github_app_private_key_ssm" {
  name   = "/${var.ssm_param_prefix}/${var.prefix}/${var.environment}/github_app_private_key"
  type   = "SecureString"
  value  = var.github_app.private_key
  key_id = local.kms_key_arn
  tags   = var.tags
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "github_app_webhook_secret_ssm" {
  name   = "/${var.ssm_param_prefix}/${var.prefix}/${var.environment}/github_app_webhook_secret"
  type   = "SecureString"
  value  = var.github_app.webhook_secret
  key_id = local.kms_key_arn
  tags   = var.tags
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "gha_runner_image_ssm" {
  name  = "/${var.ssm_param_prefix}/${var.prefix}/${var.environment}/gha_runner_image"
  type  = "String"
  value = var.gha_runner_image
  tags  = var.tags
  key_id = local.kms_key_arn
}
