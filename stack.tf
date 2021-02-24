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
  # the name of the ECS Task to be created
  aws_ecs_task_name = "${var.aws_resource_prefix}-task"
  # The name of the execution role to be created
  aws_ecs_execution_role_name = "${var.aws_resource_prefix}-ecs-execution-role"
  # tf state bucket id
  aws_s3_tf_state_bucket_id = "${var.aws_resource_prefix}-tf-state-${var.aws_region}"
  # tf state filename
  tf_state_filename = "terraform.tfstate"
  # IAM role name
  aws_iam_ecs_task_execution_role_name = "${var.aws_resource_prefix}-ecs-task-execution-role"
  # aws alb
  aws_alb_name = "${var.aws_resource_prefix}-alb-name"
  # aws target group 
  aws_tg_name = "${var.aws_resource_prefix}-tg-name"
}

resource "aws_ecr_repository" "js-app" {
  name = "${local.aws_ecr_repository_name}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = "${local.aws_s3_tf_state_bucket_id}"
  versioning {
    enabled = true
  }
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "tf_state_access_block" {
  bucket = "${aws_s3_bucket.tf_state_bucket.id}"
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

#resource "aws_s3_bucket_object" "tf_state_file" {
#  bucket = "${local.aws_s3_tf_state_bucket_id}"
#  acl    = "private"
#  key    = "${local.tf_state_filename}"
#  source = "terraform.tfstate"
#  server_side_encryption = "aws:kms"
#}

resource "aws_ecs_cluster" "jsapp_cluster" {
  name = "${local.aws_ecs_cluster_name}" # Naming the cluster
}

resource "aws_ecs_task_definition" "jsapp_task" {
  family                   = "${local.aws_ecs_task_name}"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${local.aws_ecs_task_name}",
      "image": "${aws_ecr_repository.js-app.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.jsapp_ecs_task_execution_role.arn}"
}

resource "aws_iam_role" "jsapp_ecs_task_execution_role" {
  name               = "${local.aws_iam_ecs_task_execution_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "jsapp_ecs_task_execution_role_policy" {
  role       = "${aws_iam_role.jsapp_ecs_task_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "jsapp_ecs_service" {
  name            = "${local.aws_ecs_service_name}"                             
  cluster         = "${aws_ecs_cluster.jsapp_cluster.id}"             
  task_definition = "${aws_ecs_task_definition.jsapp_task.arn}"
  launch_type     = "FARGATE"
  desired_count   = 2 # for a little redundancy 
  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}", "${aws_default_subnet.default_subnet_d.id}"]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    container_name   = "${aws_ecs_task_definition.jsapp_task.family}"
    container_port   = 3000
  }
}

resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "${var.aws_region}a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "${var.aws_region}b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "${var.aws_region}c"
}

resource "aws_default_subnet" "default_subnet_d" {
  availability_zone = "${var.aws_region}d"
}

resource "aws_alb" "jsapp_load_balancer" {
  name               = "${local.aws_alb_name}"
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}",
    "${aws_default_subnet.default_subnet_c.id}",
    "${aws_default_subnet.default_subnet_d.id}"
  ]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${local.aws_tg_name}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}"
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.jsapp_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }
}