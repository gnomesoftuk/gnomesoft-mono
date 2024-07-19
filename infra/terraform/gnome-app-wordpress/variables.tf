variable "region" {
    description = "The AWS Region"
    default = "us-east-1"
}

variable "vpc_name" {
    description = "VPC name used for subnet discovery"
    default = "gnome-workload-vpc"
}
