locals {
  account_id    = data.aws_caller_identity.current.account_id
  aws_region    = data.aws_region.current.name
  aws_partition = data.aws_partition.current.partition
  tags          = { "name" = var.prefix, "environment" = var.environment }
}
