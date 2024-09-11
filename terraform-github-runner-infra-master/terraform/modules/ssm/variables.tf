variable "github_app" {
  description = "GitHub app parameters, see your github app. Ensure the key is the base64-encoded `.pem` file (the output of `base64 app.private-key.pem`, not the content of `private-key.pem`)."
  type = object({
    id             = string
    webhook_secret = string
    private_key    = string
  })
}

variable "prefix" {
  description = "The prefix used for naming resources"
  type        = string
}

variable "ssm_param_prefix" {
  description = "The prefix used for naming SSM parameters"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "Optional CMK Key ARN to be used for Parameter Store."
  type        = string
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
}

variable "gha_runner_image" {
  description = "The name of the GitHub Actions runner image"
  type        = string
}