
provider "aws" {
	region = var.aws_region
}

locals {
	name     = "${var.name}-${var.environment}"
	env_file = "${var.env_file_bucket}${var.name}-${var.environment}.env"
	tags = {
		env     = var.environment
		purpose = var.name
	}
}

resource "aws_cloudwatch_log_group" "logs" {
	name              = "/ecs/${local.name}"
	retention_in_days = 30
	tags              = local.tags
}

# ECS cluster, service, and task definition
resource "aws_ecs_cluster" "cluster" {
	name = "${local.name}"
	tags = local.tags
}

resource "aws_ecs_task_definition" "td" {
	family                   = "${local.name}-td"
	network_mode             = "awsvpc"
	requires_compatibilities = ["FARGATE"]
	cpu                      = 512
	memory                   = 1024
	execution_role_arn       = var.task_execution_role
	container_definitions    = jsonencode([{
		name             = "${local.name}-container"
		image            = var.repository
		essential        = true
		portMappings     = [{
			protocol      = "tcp"
			containerPort = var.container_port
			hostPort      = var.container_port
		}],
		environmentFiles = [{
			value = local.env_file,
			type  = "s3"
		}],
		logConfiguration = {
			logDriver     = "awslogs",
			secretOptions = null,
			options     = {
				awslogs-group = aws_cloudwatch_log_group.logs.name,
				awslogs-region = var.aws_region,
				awslogs-stream-prefix = "ecs"
			}
		}
  }])

  volume {
		name = "efs-mount"

		efs_volume_configuration {
			file_system_id = var.task_mount_points.sourceVolume
			root_directory = var.task_mount_points.containerPath
		}
  }

	tags = local.tags
}

resource "aws_ecs_service" "service" {
	name                               = "${local.name}-service"
	cluster                            = aws_ecs_cluster.cluster.id
	task_definition                    = aws_ecs_task_definition.td.arn
	desired_count                      = var.container_count
	deployment_minimum_healthy_percent = 50
	deployment_maximum_percent         = 200
	health_check_grace_period_seconds  = 30
	launch_type                        = "FARGATE"
	scheduling_strategy                = "REPLICA"

	network_configuration {
		security_groups  = [var.sg_container_access]
		subnets          = var.private_subnets
		assign_public_ip = false
	}

	load_balancer {
		target_group_arn = aws_alb_target_group.tg.id
		container_name   = "${local.name}-container"
		container_port   = var.container_port
	}

	depends_on = [aws_alb_target_group.tg]
	tags       = local.tags
}

# Load balancer
resource "aws_lb" "lb" {
	name               = "${local.name}-alb"
	internal           = false
	load_balancer_type = "application"
	security_groups    = [var.sg_public_access]
	subnets            = var.public_subnets

	enable_deletion_protection = false
}

resource "aws_alb_target_group" "tg" {
	name        = "${local.name}-tg"
	port        = 80
	protocol    = "HTTP"
	vpc_id      = var.vpc_id
	target_type = "ip"

	health_check {
		healthy_threshold   = 3
		interval            = 30
		protocol            = "HTTP"
		matcher             = var.health_check_response_code
		timeout             = 3
		path                = var.health_check_path
		unhealthy_threshold = 2
	}

	stickiness {
		enabled = false
		type    = "lb_cookie"
	}

	depends_on = [aws_lb.lb]
}

resource "aws_alb_listener" "http" {
	load_balancer_arn = aws_lb.lb.id
	port              = 80
	protocol          = "HTTP"

	default_action {
		type = "redirect"

		redirect {
			port        = 443
			protocol    = "HTTPS"
			status_code = "HTTP_301"
		}
	}

	depends_on = [aws_lb.lb]
}

resource "aws_alb_listener" "https" {
	load_balancer_arn = aws_lb.lb.id
	port              = 443
	protocol          = "HTTPS"

	ssl_policy        = "ELBSecurityPolicy-2016-08"
	certificate_arn   = var.certificate

	default_action {
		target_group_arn = aws_alb_target_group.tg.id
		type             = "forward"
	}

	depends_on = [aws_lb.lb, aws_alb_target_group.tg]
}
