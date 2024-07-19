provider "aws" {
  region = var.region
}

locals {
  region = var.region
  name   = "ex-${basename(path.cwd)}"

  container_name = "wordpress"
  container_port = 8080

  db_instance_class = "db.t3.micro"
  db_engine_version = "8.0.35"
  db_name           = "wordpress"
  db_username       = "admin"

  tags = {
    Workspace  = local.name
    GithubRepo = "gnomesoft-mono"
    GithubOrg  = "gnomesoftuk"
  }
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

data "aws_subnets" "workload" {
  filter {
    name   = "tag:Workspace"
    values = ["gnome-workload-vpc"]
  }
  filter {
    name   = "tag:type"
    values = ["private"]
  }
}

data "aws_subnets" "lb" {
  filter {
    name   = "tag:Workspace"
    values = ["gnome-workload-vpc"]
  }
  filter {
    name   = "tag:type"
    values = ["public"]
  }
}

data "aws_subnets" "database" {
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

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.11"

  cluster_name = local.name

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

  tags = local.tags
}

################################################################################
# Service
################################################################################

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.11"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  cpu    = 1024
  memory = 4096

  # Enables ECS Exec
  enable_execute_command = true

  # Container definition(s)
  container_definitions = {

    fluent-bit = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = nonsensitive(data.aws_ssm_parameter.fluentbit.value)
      firelens_configuration = {
        type = "fluentbit"
      }
      memory_reservation = 50
      user               = "0"
    }

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
          name  = "WORDPRESS_DB_HOST"
          value = module.db.db_instance_address
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = local.db_username
        },
        {
          name  = "WORDPRESS_DB_PASSWORD"
          value = "password" // get this from a secret
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = local.db_username
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false

      dependencies = [{
        containerName = "fluent-bit"
        condition     = "START"
      }]

      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awsfirelens"
        options = {
          Name                    = "firehose"
          region                  = local.region
          delivery_stream         = "my-stream"
          log-driver-buffer-limit = "2097152"
        }
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

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this.arn
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ex_ecs"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  //subnet_ids = module.vpc.private_subnets
  subnet_ids = data.aws_subnets.workload.ids

  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  service_tags = {
    "ServiceTag" = "Tag on service level"
  }

  tags = local.tags
}



################################################################################
# Database
################################################################################

resource "aws_security_group" "database" {
  name        = "wordpress-sg"
  description = "Access to the RDS instances from the VPC"
  vpc_id      = data.aws_vpc.workload.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.workload.cidr_block]
  }

  #   ingress {
  #     from_port   = 8
  #     to_port     = 0
  #     protocol    = "icmp"
  #     cidr_blocks = ["${var.vpc_cidr_block}"]
  #   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "wordpress"

  engine            = "mysql"
  engine_version    = local.db_engine_version
  instance_class    = local.db_instance_class
  allocated_storage = 5

  db_name  = "wordpressDb"
  username = "user"
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.database.id]

  //maintenance_window = "Mon:00:00-Mon:03:00"
  //backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  //monitoring_interval    = "30"
  //monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = false

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = data.aws_subnets.database.ids

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

################################################################################
# Supporting Resources
################################################################################

data "aws_ssm_parameter" "fluentbit" {
  name = "/aws/service/aws-for-fluent-bit/stable"
}

resource "aws_service_discovery_http_namespace" "this" {
  name        = local.name
  description = "CloudMap namespace for ${local.name}"
  tags        = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id  = data.aws_vpc.workload.id
  subnets = data.aws_subnets.lb.ids
  // vpc_id  = module.vpc.vpc_id
  //subnets = module.vpc.public_subnets

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
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

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_ecs"
      }
    }
  }

  target_groups = {
    ex_ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = local.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }

  tags = local.tags
}
