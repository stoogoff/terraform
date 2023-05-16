
resource "aws_instance" "couchdb" {
	ami                    = local.couch_ami
	instance_type          = local.couch_instance
	vpc_security_group_ids = [aws_security_group.container_access.id]
	subnet_id              = module.network.public_subnets[0]
	key_name               = "stoo@lamorak"

	root_block_device {
		volume_size = 20
	}

	tags = {
		Name = "Web and DB Server"
		env = local.environment
	}

	user_data = <<EOF
#!/bin/bash

docker run -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=${var.db_password} \
	-v /home/ubuntu/couchdb:/opt/couchdb/data \
	-p 5984:5984 \
	-d couchdb:3.2.2
EOF
}

# Load balancer
resource "aws_alb" "couchdb" {
	name               = "couchdb-${local.environment}-alb"
	internal           = false
	load_balancer_type = "application"
	security_groups    = [aws_security_group.web_access.id]
	subnets            = module.network.public_subnets

	enable_deletion_protection = false
}

resource "aws_alb_target_group" "targets" {
	count = length(local.domains)

	name        = "${local.domains[count.index].name}-${local.environment}-tg"
	port        = local.domains[count.index].port
	protocol    = "HTTP"
	vpc_id      = module.network.vpc_id
	target_type = "instance"

	health_check {
		healthy_threshold   = 3
		interval            = 30
		protocol            = "HTTP"
		matcher             = "200"
		timeout             = 3
		path                = local.domains[count.index].health_check
		unhealthy_threshold = 2
	}

	depends_on = [aws_alb.couchdb]
}

resource "aws_alb_target_group_attachment" "attachments" {
	count = length(aws_alb_target_group.targets)

	target_group_arn = element(aws_alb_target_group.targets.*.arn, count.index)
	target_id        = aws_instance.couchdb.id
}

resource "aws_alb_listener" "couchdb_http" {
	load_balancer_arn = aws_alb.couchdb.id
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

	depends_on = [aws_alb.couchdb]
}

resource "aws_alb_listener" "couchdb_https" {
	load_balancer_arn = aws_alb.couchdb.id
	port              = 443
	protocol          = "HTTPS"

	ssl_policy        = "ELBSecurityPolicy-2016-08"
	certificate_arn   = var.certificate_euwest1

	default_action {
		target_group_arn = aws_alb_target_group.targets[0].id
		type             = "forward"
	}

	depends_on = [aws_alb.couchdb, aws_alb_target_group.targets[0]]
}

resource "aws_lb_listener_rule" "rules" {
	count = length(local.domains)

	listener_arn = aws_alb_listener.couchdb_https.arn
	priority     = 100 - count.index

	action {
		type             = "forward"
		target_group_arn = element(aws_alb_target_group.targets.*.id, count.index)
	}

	condition {
		host_header {
			values = [local.domains[count.index].domain]
		}
	}
}
