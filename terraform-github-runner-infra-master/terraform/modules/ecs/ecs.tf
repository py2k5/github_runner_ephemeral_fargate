data "aws_subnets" "backend_subnets" {
  filter {
    name   = "tag:Name"
    values = ["*-BackEnd-*"]
  }
}
data "aws_vpc" "internal_vpc" {
  filter {
    name   = "tag:Name"
    values = ["*-Internal"]
  }
}

# Demo ECS Cluster where runner Tasks will be deployed
resource "aws_ecs_cluster" "github_actions_cluster" {
  name = "${var.prefix}-${var.environment}-${var.ecs_cluster}"
  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "github_actions_cluster_capacity" {
  cluster_name       = aws_ecs_cluster.github_actions_cluster.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }
}

resource "aws_ecs_task_definition" "ccoe-github-actions-runner-taskdef" {
  container_definitions = jsonencode([
    {
      "name" : var.ecs_container_name,
      "image" : var.gha_runner_image,
      "cpu" : 512,
      "memory" : 1024,
      "command": [
                "./ephemeral_runner.sh"
            ],
      "environment" : [
        {
            "name": "WORKFLOW_NAME",
            "value": ""
        },
        {
            "name": "LABELS",
            "value": ""
        },
        {
            "name": "REG_TOKEN",
            "value": ""
        },
        {
            "name": "GITHUB_ORG",
            "value": ""
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "/ecs/${var.prefix}-${var.environment}-logs",
          "awslogs-region" : "ap-southeast-2",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    }
  ])
  family                   = "${var.prefix}-${var.environment}-taskdef"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ccoe_github_actions_execrole.arn
  task_role_arn            = aws_iam_role.ccoe_github_actions_taskrole.arn
}

resource "aws_ecs_service" "github_actions_cluster_service" {
  name            = "gha-runner-service"
  cluster         = aws_ecs_cluster.github_actions_cluster.arn
  task_definition = aws_ecs_task_definition.ccoe-github-actions-runner-taskdef.arn
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = data.aws_subnets.backend_subnets.ids
    security_groups = [aws_security_group.gha_security_group.id]
  }
}

resource "aws_security_group" "gha_security_group" {
  name        = "${var.prefix}-${var.environment}-security-group"
  description = "Security Group without ingress rules for the GHA runners"
  vpc_id      = data.aws_vpc.internal_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "github_actions_task_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ccoe_github_actions_execrole_policy" {
  statement {
    sid       = "ExecrolePolicy"
    actions   = ["ssm:GetParameters",
                 "ecr:GetAuthorizationToken",
                 "ecr:BatchCheckLayerAvailability",
                 "ecr:GetDownloadUrlForLayer",
                 "ecr:BatchGetImage",
                 "logs:CreateLogStream",
                 "logs:PutLogEvents",
                 "logs:CreateLogGroup"]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role" "ccoe_github_actions_execrole" {
  name                = "ccoeGithubActionsExecrole"
  assume_role_policy  = data.aws_iam_policy_document.github_actions_task_trust.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  inline_policy {
    name   = "GetEcrAndCreateLogs"
    policy = data.aws_iam_policy_document.ccoe_github_actions_execrole_policy.json
  }
}

data "aws_iam_policy_document" "github_actions_taskrole_policy" {
  statement {
    sid       = "AssumeCCOEGHARoles"
    actions   = ["logs:CreateLogStream",
                "logs:PutLogEvents"]
    effect    = "Allow"
    resources = [ "*" ]
  }
}

resource "aws_iam_role" "ccoe_github_actions_taskrole" {
  name               = "ccoeGithubActionsTaskrole"
  assume_role_policy = data.aws_iam_policy_document.github_actions_task_trust.json
  inline_policy {
    name   = "ccoe-github-actions-taskrole-policy"
    policy = data.aws_iam_policy_document.github_actions_taskrole_policy.json
  }
}

