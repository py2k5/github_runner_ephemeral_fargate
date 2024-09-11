output "task_definition" {
    value = {
        name = aws_ecs_task_definition.ccoe-github-actions-runner-taskdef.family
        arn  = aws_ecs_task_definition.ccoe-github-actions-runner-taskdef.arn
    }
}

output "security_groups" {
  value = aws_security_group.gha_security_group.id
}

output "subnet_ids" {
  value = join(",",data.aws_subnets.backend_subnets.ids)
}


output "cluster" {
  value = {
    ecs_cluster = {
      name = aws_ecs_cluster.github_actions_cluster.name
      arn  = aws_ecs_cluster.github_actions_cluster.arn
    }
  }
}   