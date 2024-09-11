data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}
# Repository Where Runner container  image is stored
# data "aws_ecr_repository" "ccoe_runner_agent" {
#   name = var.ecr_repository
#   registry_id = "194167259353"
# }

# data "aws_ecs_task_definition" "eric-gha-testing-taskdef" {
#   task_definition = var.ecs_task_definition
# }

# data "aws_ecs_cluster" "github_actions" {
#   cluster_name = var.ecs_cluster
# }
