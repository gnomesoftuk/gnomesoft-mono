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
  region = var.region
  name   = "ex-${basename(path.cwd)}"

  container_name = "wordpress"
  container_port = 8080

  db_name = "wordpressDB"
  db_port = 3306
}

################################################################################
# Network Info - auto discovery
################################################################################

data "aws_vpc" "workload" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Workspace"
    values = ["gnome-workload-vpc"]
  }
  filter {
    name   = "tag:type"
    values = ["private"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Workspace"
    values = ["gnome-workload-vpc"]
  }
  filter {
    name   = "tag:type"
    values = ["public"]
  }
}

data "aws_subnets" "internal" {
  filter {
    name   = "tag:Workspace"
    values = ["gnome-workload-vpc"]
  }
  filter {
    name   = "tag:type"
    values = ["internal"]
  }
}

################################################################################
# Cluster
################################################################################

data "aws_ecs_cluster" "ecs-mongo" {
  cluster_name = var.deployment_cluster_name
}

################################################################################
# Service
# 
# deploying applications and utilities with terraform is problematic
# because we really don't get that much control over the process.
# In this case I want to deploy our service, and also a db setup task to
# configure database creation - terraform does not allow us to deploy tasks in this way.
#
# Instead we should consider using CodeDeploy to deploy services to ECS rather than
# trying to do it directly from Terraform.
################################################################################

# module "ecs_admin_shell" {
#   source  = "terraform-aws-modules/ecs/aws//modules/service"
#   version = "~> 5.11"

#   name        = "admin-shell"
#   cluster_arn = module.ecs_cluster.arn

#   cpu    = 512
#   memory = 1024

#   enable_execute_command = true

#   container_definitions = {

#   }

#   subnet_ids = data.aws_subnets.public.ids
# }

# // create a one-off ECS task for our database setup instructions
# module "ecs_db_setup" {
#   source  = "terraform-aws-modules/ecs/aws//modules/task"
#   version = "~> 5.11"

#   name        = "db-setup"
#   cluster_arn = module.ecs_cluster.arn

#   enable_execute_command = true

#   cpu    = 512
#   memory = 1024

#   container_definitions = {
#     container_name = local.container_name
#     cpu            = 512
#     memory         = 1024
#     essential      = true
#     image          = "public.ecr.aws/bitnami/wordpress:6.6.0"

#     environment = [

#     ]


#     # Example image requires access to write to root filesystem
#     readonly_root_filesystem = false

#     log_configuration = {
#       logdriver = "awslogs"
#       options = {
#         "awslogs-group" : "/ecs/db-setup"
#       }
#     }

#     linux_parameters = {
#       capabilities = {
#         add = []
#         drop = [
#           "NET_RAW"
#         ]
#       }
#       init_process_enabled = true
#     }
#   }

#   subnet_ids = data.aws_subnets.private.ids
# }

# module "ecs_service" {
#   source  = "terraform-aws-modules/ecs/aws//modules/service"
#   version = "~> 5.11"

#   name        = local.name
#   cluster_arn = module.ecs_cluster.arn

#   cpu    = 1024
#   memory = 4096

#   # Enables ECS Exec
#   enable_execute_command = false

#   # Container definition(s)
#   container_definitions = {

#     # fluent-bit = {
#     #   cpu       = 512
#     #   memory    = 1024
#     #   essential = true
#     #   image     = nonsensitive(data.aws_ssm_parameter.fluentbit.value)
#     #   firelens_configuration = {
#     #     type = "fluentbit"
#     #   }
#     #   memory_reservation = 50
#     #   user               = "0"
#     # }

#     (local.container_name) = {
#       cpu       = 512
#       memory    = 1024
#       essential = true
#       image     = "public.ecr.aws/bitnami/wordpress:6.6.0"
#       port_mappings = [
#         {
#           name          = local.container_name
#           containerPort = local.container_port
#           hostPort      = local.container_port
#           protocol      = "tcp"
#         }
#       ]

#       environment = [
#         {
#           name  = "WORDPRESS_DATABASE_HOST"
#           value = module.db.db_instance_address
#         },
#         {
#           name  = "WORDPRESS_DATABASE_USER"
#           value = var.db_username
#         },
#         {
#           name  = "WORDPRESS_DATABASE_PASSWORD"
#           value = var.db_password
#         },
#         {
#           name  = "WORDPRESS_DATABASE_NAME"
#           value = local.db_name
#         }
#       ]

#       # Example image used requires access to write to root filesystem
#       readonly_root_filesystem = false

#       #   dependencies = [{
#       #     containerName = "fluent-bit"
#       #     condition     = "START"
#       #   }]

#       enable_cloudwatch_logging = true
#       log_configuration = {
#         logdriver = "awslogs"
#         # logDriver = "awsfirelens"
#         # options = {
#         #   Name                    = "firehose"
#         #   region                  = local.region
#         #   delivery_stream         = "my-stream"
#         #   log-driver-buffer-limit = "2097152"
#         # }
#       }

#       linux_parameters = {
#         capabilities = {
#           add = []
#           drop = [
#             "NET_RAW"
#           ]
#         }
#       }

#       # Not required for fluent-bit, just an example
#       #   volumes_from = [{
#       #     sourceContainer = "fluent-bit"
#       #     readOnly        = false
#       #   }]

#       memory_reservation = 100
#     }
#   }

#   service_connect_configuration = {
#     namespace = aws_service_discovery_http_namespace.this.arn
#     service = {
#       client_alias = {
#         port     = local.container_port
#         dns_name = local.container_name
#       }
#       port_name      = local.container_name
#       discovery_name = local.container_name
#     }
#   }

#   load_balancer = {
#     service = {
#       target_group_arn = module.alb.target_groups["ex_ecs"].arn
#       container_name   = local.container_name
#       container_port   = local.container_port
#     }
#   }

#   subnet_ids = data.aws_subnets.private.ids

#   security_group_rules = {
#     alb_ingress_3000 = {
#       type                     = "ingress"
#       from_port                = local.container_port
#       to_port                  = local.container_port
#       protocol                 = "tcp"
#       description              = "Service port"
#       source_security_group_id = module.alb.security_group_id
#     }
#     egress_all = {
#       type        = "egress"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }
# }

resource "aws_security_group" "ecs_service" {
  name        = "wordpress-service-sg"
  description = "Security group for the ECS service"
  vpc_id      = data.aws_vpc.workload.id
}

data "aws_security_group" "load_balancer" {
  filter {
    name   = "tag:Workspace"
    values = [var.gnome_ecs_cluster_workspace]
  }
}

// allow traffic IN from the ALB on the container's port
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.ecs_service.id
  from_port                    = local.container_port
  to_port                      = local.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.load_balancer.id
}

// allow traffic OUT to anywhere
resource "aws_vpc_security_group_egress_rule" "app_to_anywhere" {
  security_group_id = aws_security_group.ecs_service.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

################################################################################
# Bastion
################################################################################

# resource "aws_security_group" "bastion" {
#   name        = "bastion-sg"
#   description = "Access to the bastion host via SSH"
#   vpc_id      = data.aws_vpc.workload.id
# }

# resource "aws_vpc_security_group_ingress_rule" "bastion_from_anywhere" {
#   security_group_id = aws_security_group.bastion.id
#   from_port         = 22
#   to_port           = 22
#   ip_protocol       = "tcp"
#   cidr_ipv4         = "0.0.0.0/0"
# }

# resource "aws_vpc_security_group_egress_rule" "bastion_to_anywhere" {
#   security_group_id = aws_security_group.bastion.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"
# }

# resource "tls_private_key" "pk" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "bastion" {
#   key_name   = "bastion"
#   public_key = tls_private_key.pk.public_key_openssh
# }

# module "bastion" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.6"

#   name = "mysql-bastion"

#   instance_type          = "t2.micro"
#   key_name               = aws_key_pair.bastion.key_name
#   monitoring             = false
#   vpc_security_group_ids = [aws_security_group.bastion.id]
#   subnet_id              = data.aws_subnets.public.ids[0]
# }

################################################################################
# Database
################################################################################

resource "aws_security_group" "database" {
  name        = "wordpress-sg"
  description = "Access to the RDS instances from the VPC"
  vpc_id      = data.aws_vpc.workload.id
}

// allow traffic IN from the ECS service on the database's port
resource "aws_vpc_security_group_ingress_rule" "db_from_application" {
  security_group_id            = aws_security_group.database.id
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_service.id
}

// allow traffic OUT to anywhere
resource "aws_vpc_security_group_egress_rule" "db_to_anywhere" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "wordpress"

  engine            = "mysql"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = 5

  db_name  = local.db_name
  username = var.db_username
  password = var.db_password
  port     = local.db_port
  //manage_master_user_password = true  // SECURITY: we must replace password with this

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.database.id]

  //maintenance_window = "Mon:00:00-Mon:03:00"
  //backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  //monitoring_interval    = "30"
  //monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = false

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = data.aws_subnets.internal.ids

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  # Database Deletion Protection
  deletion_protection = true

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  #   options = [
  #     {
  #       option_name = "MARIADB_AUDIT_PLUGIN"

  #       option_settings = [
  #         {
  #           name  = "SERVER_AUDIT_EVENTS"
  #           value = "CONNECT"
  #         },
  #         {
  #           name  = "SERVER_AUDIT_FILE_ROTATIONS"
  #           value = "37"
  #         },
  #       ]
  #     },
  #   ]
}