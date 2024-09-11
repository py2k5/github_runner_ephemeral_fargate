
variable "prefix" {
  description = "The prefix used for naming resources"
  type        = string
  default     = "github-actions-ephemeral"
}

variable "ssm_param_prefix" {
  description = "The prefix used for naming SSM parameters"
  type        = string
  default     = "ccoe"
}

variable "environment" {
  description = "value of the environment"
  type        = string
  default     = "dev"
}


### Runner lambda config
variable "github_app" {
  description = "GitHub app parameters, see your github app."
  type = object({
    id             = string
    webhook_secret = string
    private_key    = string
  })
  default = {
    id = "updateme"
    webhook_secret = "updateme"
    private_key = "updateme"
  }
}

variable "runner_group_name" {
  description = "Name of the runner group."
  type        = string
  default     = "Default"
}


variable "layer_name" {
  description = "name of the layer"
  type        = string
  default = "ghaEphemeralLayer"
}

variable "runner_lambda_timeout" {
  description = "Timeout of the runner lambda in seconds."
  type        = number
  default     = 60
}


variable "role_permissions_boundary" {
  description = "Permissions boundary that will be added to the created roles."
  type        = string
  default     = null
}


variable "kms_key_arn" {
  description = "Optional CMK Key ARN to be used for Parameter Store. This key must be in the current account."
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


variable "lambda_security_group_ids" {
  description = "List of security group IDs associated with the Lambda function."
  type        = list(string)
  default     = []
}


variable "log_level" {
  description = "Logging level for lambda logging. Valid values are  'trace', 'debug', 'info', 'warn', 'error'."
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


variable "gha_runner_image" {
  description = "The name of the GitHub Actions runner image"
  type        = string
  default     = "194167259353.dkr.ecr.ap-southeast-2.amazonaws.com/ccoe-ecr-ubuntu-githubactions-ephemeral:latest"
}

variable "ecs_cluster" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "ecs-cluster"
}

variable "ecs_container_name" {
  description = "value of the container name"
  type        = string
  default     = "ccoe-ecr-ubuntu-githubactions-ephemeral"
}