variable "prefix" {
  description = "The prefix used for naming resources"
  type        = string 
}
variable "ecs_cluster" {
  description = "The ECS cluster name"
  type        = string
}

variable "environment" {
  description = "environment"
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

variable "ecs_container_name" {
  description = "The name of the container in the ECS task definition"
  type        = string
}