provider "aws" {
  version = "~> 3.5.0"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

locals {
  # The name of the CloudFormation stack to be created for the VPC and related resources
  aws_vpc_stack_name = "${var.aws_resource_prefix}-vpc-stack"
  # The name of the CloudFormation stack to be created for the ECS service and related resources
  aws_ecs_service_stack_name = "${var.aws_resource_prefix}-svc-stack"
  # The name of the ECR repository to be created
  aws_ecr_repository_name = "${var.aws_resource_prefix}"
  # The name of the ECS cluster to be created
  aws_ecs_cluster_name = "${var.aws_resource_prefix}-cluster"
  # The name of the ECS service to be created
  aws_ecs_service_name = "${var.aws_resource_prefix}-service"
  # The name of the execution role to be created
  aws_ecs_execution_role_name = "${var.aws_resource_prefix}-ecs-execution-role"
}

resource "aws_ecr_repository" "js-app" {
  name = "${local.aws_ecr_repository_name}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
