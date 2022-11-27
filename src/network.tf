
# Network
module "network" {
	source = "../modules/network"

	vpc_name           = local.environment
	cidr_block         = "10.0.0.0/16"
	public_cidr_block  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
	private_cidr_block = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

# Public web access security group
# has ports 80 and 443 public access
resource "aws_security_group" "web_access" {
	name        = "${local.environment}-web"
	description = "Public Web Access"
	vpc_id      = module.network.vpc_id

	ingress {
		description      = "HTTPS"
		from_port        = 443
		to_port          = 443
		protocol         = "tcp"
		cidr_blocks      = ["0.0.0.0/0"]
	}

	ingress {
		description      = "HTTP"
		from_port        = 80
		to_port          = 80
		protocol         = "tcp"
		cidr_blocks      = ["0.0.0.0/0"]
	}

	egress {
		from_port        = 0
		to_port          = 0
		protocol         = "-1"
		cidr_blocks      = ["0.0.0.0/0"]
		ipv6_cidr_blocks = ["::/0"]
	}

	tags = {
		Name = "${local.environment}-web"
	}
}

# Restricted access from the loadbalancer to the containers
# container ports is open to the web_access security group only
resource "aws_security_group" "container_access" {
	name        = "${local.environment}-container"
	description = "Container internal access"
	vpc_id      = module.network.vpc_id

	ingress {
		description     = local.website.name
		from_port       = local.website.port
		to_port         = local.website.port
		protocol        = "tcp"
		security_groups = [aws_security_group.web_access.id]
	}

	ingress {
		description     = local.couchdb.name
		from_port       = local.couchdb.port
		to_port         = local.couchdb.port
		protocol        = "tcp"
		#self            = true
		cidr_blocks      = ["0.0.0.0/0"]
		security_groups = [aws_security_group.web_access.id]
	}

	ingress {
		description      = "SSH"
		from_port        = 22
		to_port          = 22
		protocol         = "tcp"
		cidr_blocks      = ["0.0.0.0/0"]
	}

	egress {
		from_port        = 0
		to_port          = 0
		protocol         = "-1"
		cidr_blocks      = ["0.0.0.0/0"]
		ipv6_cidr_blocks = ["::/0"]
	}

	tags = {
		Name = "${local.environment}-container"
	}
}
