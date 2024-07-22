variable "region" {
    description = "The AWS Region"
    default = "us-east-1"
}

variable "vpc_name" {
    description = "VPC name used for subnet discovery"
    default = "gnome-workload-vpc"
}

variable "db_instance_class" {
    default = "db.t3.micro"
}

variable "db_engine_version" {
    default = "8.0.35"
}

variable "db_username" {
    default =  "admin"
}

variable "db_password" {
    default = ".QovqLe@vu2WTn2o"
    sensitive = true
}
  
