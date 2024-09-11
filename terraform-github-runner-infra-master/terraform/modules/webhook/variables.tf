variable "prefix" {
  description = "The prefix used for naming resources"
  type        = string
}

variable "environment" {
  description = "environment"
  type        = string
}
variable "ecs_cluster_name" {
  description = "The name of the ECS cluster where the webhook will be deployed."
  type        = string
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster where the webhook will be deployed."
  type        = string
}

variable "ecs_container_name" {
  description = "The name of the container in the ECS task definition."
  type        = string
  
}
variable "task_definition" {
  description = "The name of the task definition that will be used for the webhook."
  type        = string
}

variable "task_definition_arn" {
  description = "The ARN of the task definition that will be used for the webhook."
  type        = string
}

variable "subnet_ids" {
  description = "The list of subnet IDs where the webhook will be deployed."
  type        = string
}

variable "security_groups" {
  description = "Security group IDs that will be used for the runners."
  type        = string
}


variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
}

variable "github_app_webhook_secret" {
  description = "webhook secret for the github app"
  type = object({
    name = string
    arn  = string
  })
}

variable "github_app_id" {
  description = "value of the github app id"
  type = object({
    name = string
    arn  = string
  })
}

variable "github_app_private_key" {
  description = "value of the github private app key"
  type = object({
    name = string
    arn  = string
  })
}

variable "gha_runner_image" {
  description = "runner image parameter for the github actions runner"
  type = object({
    name = string
    arn  = string
  })
}

variable "lambda_timeout" {
  description = "Time out of the lambda in seconds."
  type        = number
}

variable "role_permissions_boundary" {
  description = "Permissions boundary that will be added to the created role for the lambda."
  type        = string
  default     = null
}


variable "logging_retention_in_days" {
  description = "Specifies the number of days you want to retain log events for the lambda log group. Possible values are: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
  type        = number
  default     = 180
}

variable "logging_kms_key_id" {
  description = "Specifies the kms key id to encrypt the logs with"
  type        = string
  default     = null
}


variable "kms_key_arn" {
  description = "Optional CMK Key ARN to be used for Parameter Store."
  type        = string
  default     = null
}

variable "log_level" {
  description = "Logging level for lambda logging. Valid values are  'silly', 'trace', 'debug', 'info', 'warn', 'error', 'fatal'."
  type        = string
  default     = "info"
  validation {
    condition = anytrue([
      var.log_level == "trace",
      var.log_level == "debug",
      var.log_level == "info",
      var.log_level == "warn",
      var.log_level == "error",
    ])
    error_message = "`log_level` value not valid. Valid values are 'trace', 'debug', 'info', 'warn', 'error'."
  }
}

variable "lambda_runtime" {
  description = "AWS Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "lambda_architecture" {
  description = "AWS Lambda architecture. Lambda functions using Graviton processors ('arm64') tend to have better price/performance than 'x86_64' functions. "
  type        = string
  default     = "x86_64"
  validation {
    condition     = contains(["arm64", "x86_64"], var.lambda_architecture)
    error_message = "`lambda_architecture` value is not valid, valid values are: `arm64` and `x86_64`."
  }
}

variable "layer_name" {
  description = "name of the layer"
  type        = string
}

variable "runner_lambda_handler" {
  description = "value of the handler for the lambda"
  type        = string
  default     = "lambda.handler"
}
