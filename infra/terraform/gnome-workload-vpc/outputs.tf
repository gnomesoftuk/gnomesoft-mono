################################################################################
# Self Managed Node Group
################################################################################

output "vpc_id" {
  description = "The unique AWS ID for the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block (range of Ips) supported by the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "A list of public subnet IDs in the VPC"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "A list of private subnet IDs in the VPC"
  value       = module.vpc.private_subnets
}
