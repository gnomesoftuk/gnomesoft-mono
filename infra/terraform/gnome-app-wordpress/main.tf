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
  name = basename(path.cwd)

  http_port = 80

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
    values = [var.vpc_name]
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
# ECS Service Automation - not currently used
################################################################################


# module "codedeploy" {
#   source                     = "../modules/codedeploy-ecs"

#   name                       = "gnome-app-wordpress-deploy"
#   ecs_cluster_name           = var.deployment_cluster_name
#   ecs_service_name           = "gnome-app-wordpress" // do I have to deploy this first ?
#   lb_listener_arns           = ["${var.lb_listener_arns}"]
#   blue_lb_target_group_name  = "${var.blue_lb_target_group_name}"
#   green_lb_target_group_name = "${var.green_lb_target_group_name}"
# }

################################################################################
# Service
#
# Deploying applications and utilities with terraform is problematic
# because we really don't get that much control over the process.
#
# As an improvement to this configuration we could use the CodeDeploy
# configuration above to set up a deployment pipeline outside of
# terraform.
################################################################################

data "aws_ecs_cluster" "deployment_cluster" {
  cluster_name = var.deployment_cluster_name
}

data "aws_lb" "cluster_service_lb" {
  name = var.alb_name
}

# Find the listener we are attaching the service to
data "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.cluster_service_lb.arn
  port              = local.http_port
}

# Find the security group attached to the load balancer
# so we can grant ingress from it
data "aws_security_group" "load_balancer" {
  filter {
    name   = "tag:LB"
    values = [var.alb_name]
  }
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.11"

  name        = local.name
  cluster_arn = data.aws_ecs_cluster.deployment_cluster.arn

  cpu    = 1024
  memory = 4096

  # Enables ECS Exec
  enable_execute_command = false

  # Container definition(s)
  container_definitions = {

    # fluent-bit = {
    #   cpu       = 512
    #   memory    = 1024
    #   essential = true
    #   image     = nonsensitive(data.aws_ssm_parameter.fluentbit.value)
    #   firelens_configuration = {
    #     type = "fluentbit"
    #   }
    #   memory_reservation = 50
    #   user               = "0"
    # }

    # sql-admin = {

    #   container_name = local.container_name
    #   cpu            = 512
    #   memory         = 1024
    #   essential      = true
    #   image          = "joseluisq/alpine-mysql-client"

    #   environment = [
    #     {
    #       name  = "DB_PROTOCOL"
    #       value = "tcp"
    #     },
    #     {
    #       name  = "DB_HOST"
    #       value = module.db.db_instance_address
    #     },
    #     {
    #       name  = "DB_PORT"
    #       value = local.db_port
    #     },
    #     {
    #       name  = "DB_DEFAULT_CHARACTER_SET"
    #       value = "utf8"
    #     },
    #   ]

    #   # Example image requires access to write to root filesystem
    #   readonly_root_filesystem = false

    #   log_configuration = {
    #     logdriver = "awslogs"
    #     options = {
    #       "awslogs-group" : "/ecs/db-setup"
    #     }
    #   }

    #   linux_parameters = {
    #     capabilities = {
    #       add = []
    #       drop = [
    #         "NET_RAW"
    #       ]
    #     }
    #     init_process_enabled = true
    #   }

    # }

    (local.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "public.ecr.aws/bitnami/wordpress:6.6.0"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "WORDPRESS_DATABASE_HOST"
          value = module.db.db_instance_address
        },
        {
          name  = "WORDPRESS_DATABASE_USER"
          value = var.db_username
        },
        {
          name  = "WORDPRESS_DATABASE_PASSWORD"
          value = var.db_password
        },
        {
          name  = "WORDPRESS_DATABASE_NAME"
          value = local.db_name
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false

      dependencies = [{
        containerName = "sql-admin"
        condition     = "START"
      }]

      enable_cloudwatch_logging = true
      log_configuration = {
        logdriver = "awslogs"
        # logDriver = "awsfirelens"
        # options = {
        #   Name                    = "firehose"
        #   region                  = local.region
        #   delivery_stream         = "my-stream"
        #   log-driver-buffer-limit = "2097152"
        # }
      }

      linux_parameters = {
        capabilities = {
          add = []
          drop = [
            "NET_RAW"
          ]
        }
      }

      # Not required for fluent-bit, just an example
      #   volumes_from = [{
      #     sourceContainer = "fluent-bit"
      #     readOnly        = false
      #   }]

      memory_reservation = 100
    }
  }

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

  load_balancer = {
    service = {
      target_group_arn = data.aws_lb_listener.http.arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = data.aws_subnets.private.ids
  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = data.aws_security_group.load_balancer.id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
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
  referenced_security_group_id = module.ecs_service.security_group_id
}

// allow traffic OUT to anywhere
resource "aws_vpc_security_group_egress_rule" "db_to_anywhere" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.8"

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

  # For a production DB we want these options enabled, for now they are disabled
  blue_green_update = {
    enabled = false
  }
  //maintenance_window = "Mon:00:00-Mon:03:00"
  //backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  //monitoring_interval    = "30"
  //monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = false
  deletion_protection    = false

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = data.aws_subnets.internal.ids

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"




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
