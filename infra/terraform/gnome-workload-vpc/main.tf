provider "aws" {
  region = local.region
}

locals {
  name   = basename(path.cwd)
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  #azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags = {
    Workspace  = local.name
    GithubRepo = "gnomesoft-mono"
    GithubOrg  = "gnomesoftuk"
  }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.9"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  # tag subnets to support auto-discovery for services
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "type"                   = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
    "type"                            = "private"
  }

  intra_subnet_tags = {
    "type" = "internal"
  }

  tags = local.tags
}
