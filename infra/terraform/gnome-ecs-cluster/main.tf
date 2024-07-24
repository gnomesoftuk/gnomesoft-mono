provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Workspace  = local.name
      GithubRepo = "gnomesoft-mono"
      GithubOrg  = "gnomesoftuk"
    }
  }
}

locals {
  name      = basename(path.cwd)
  http_port = 80
}

################################################################################
# Network Info - auto discovery
################################################################################

data "aws_vpc" "workload" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
  state = "available"
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.workload.id]
  }
  filter {
    name   = "tag:type"
    values = ["public"]
  }
}

################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.11"

  cluster_name = var.ecs_cluster_name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = {
    Purpose = "Hosting workloads"
  }
}

################################################################################
# Application Load Balancer
################################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = var.alb_name

  load_balancer_type = "application"

  vpc_id  = data.aws_vpc.workload.id
  subnets = data.aws_subnets.public.ids

  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = local.http_port
      to_port     = local.http_port
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = data.aws_vpc.workload.cidr_block
    }
  }

  // Use an empty HTTP listener for now as we don't have a domain
  // set up for TLS
  listeners = {
    http = {
      port     = local.http_port
      protocol = "HTTP"

      # forward = {
      #   target_group_key = "ex_ecs"
      # }
      default_action = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "No route found"
        status_code  = 404
      }
    }
  }
}
