
# Create SSM secret config
module "ssm" {
  source = "./modules/ssm"

  kms_key_arn = var.kms_key_arn
  prefix      = var.prefix
  ssm_param_prefix = var.ssm_param_prefix
  environment = var.environment
  github_app  = var.github_app
  tags        = local.tags
  gha_runner_image = var.gha_runner_image
}

module "ecs" {
  source = "./modules/ecs"

  environment               = var.environment
  prefix                    = var.prefix
  gha_runner_image     = var.gha_runner_image
  ecs_cluster               = var.ecs_cluster
  ecs_container_name        = var.ecs_container_name
  tags                      = local.tags
}
# Creates the webhook api/lambdas for workflow events
module "webhook" {
  source = "./modules/webhook"

  environment               = var.environment
  prefix                    = var.prefix
  tags                      = local.tags
  kms_key_arn               = var.kms_key_arn
  github_app_webhook_secret = module.ssm.parameters.github_app_webhook_secret
  github_app_id             = module.ssm.parameters.github_app_id
  github_app_private_key     = module.ssm.parameters.github_app_private_key
  gha_runner_image          =  module.ssm.parameters.gha_runner_image

  layer_name                = var.layer_name
  lambda_runtime                                = var.lambda_runtime
  lambda_architecture                           = var.lambda_architecture
  lambda_timeout                                = var.runner_lambda_timeout
  logging_retention_in_days                     = var.logging_retention_in_days
  logging_kms_key_id                            = var.logging_kms_key_id
  role_permissions_boundary                     = var.role_permissions_boundary
  log_level                                     = var.log_level
  subnet_ids                                    = module.ecs.subnet_ids
  security_groups                               = module.ecs.security_groups
  ecs_cluster_name                              = module.ecs.cluster.ecs_cluster.name
  ecs_cluster_arn                               = module.ecs.cluster.ecs_cluster.arn
  task_definition                               = module.ecs.task_definition.name
  task_definition_arn                           = module.ecs.task_definition.arn
  ecs_container_name                            = var.ecs_container_name
}


