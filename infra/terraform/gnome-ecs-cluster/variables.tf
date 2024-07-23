variable "region" {
    description = "The AWS Region"
    default = "us-east-1"
}

variable "vpc_name" {
    description = "VPC name used for subnet discovery"
    default = "gnome-workload-vpc"
}

variable "ecs_cluster_name" {
    description = "Name of the ECS cluster"
    default = "gnome-workload-cluster"
}

variable "alb_name" {
    description = "Name of the ALB"
    default = "gnome-workload-alb"
}
  
