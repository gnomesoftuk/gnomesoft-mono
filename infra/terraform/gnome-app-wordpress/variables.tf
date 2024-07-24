variable "region" {
  type        = string
  description = "The AWS region to deploy to"
  default     = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "VPC name used for subnet discovery"
  default     = "gnome-workload-vpc"
}

variable "deployment_cluster_name" {
  type        = string
  description = "The ECS cluster to deploy to"
  default     = "gnome-workload-cluster"
}

variable "alb_name" {
  type        = string
  description = "Name of the ALB"
  default     = "gnome-workload-alb"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_engine_version" {
  type    = string
  default = "8.0.35"
}

variable "db_username" {
  type        = string
  description = "Administrative user for the database"
  default     = "admin"
}

variable "db_password" {
  type        = string
  default     = ".QovqLe@vu2WTn2o"
  description = "Unsafe password for database - will be replaced"
  sensitive   = true
}
