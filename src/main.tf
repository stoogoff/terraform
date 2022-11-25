
locals {
	environment     = "production"
	aws_region      = "eu-west-2"
	env_file_bucket = "arn:aws:s3:::weevolve-data/fargate"
	task_name       = "container-role"
	couch_instance  = "t3.micro"
	couch_ami       = "ami-0114eaef9a5a23d30"

	couchdb = {
		name = "Couch DB"
		port = 5984
	}
	website = {
		name = "Website"
		port = 3000
	}
}

provider "aws" {
	region = local.aws_region
}

resource "aws_instance" "couchdb" {
  ami                    = local.couch_ami
  instance_type          = local.couch_instance
  vpc_security_group_ids = [aws_security_group.container_access.id]
	subnet_id              = module.network.private_subnets[0]
	key_name               = "stoo@lamorak"

	root_block_device {
		volume_size = 30
	}

  tags = {
    Name = local.couchdb.name
    env = local.environment
  }
}

/*resource "aws_route53_record" "db" {
	zone_id = var.zone_id
	name    = "db.stoogoff.com"
	type    = "CNAME"
	ttl     = 300
	records = [module.couch.loadbalancer.dns]
}*/

/*
# Website Fargate cluster
module "website" {
  source = "../modules/fargate"

	name                = "stoogoff"
	aws_region          = local.aws_region
	environment         = local.environment
	certificate         = var.certificate
	task_execution_role = aws_iam_role.ecs_task_execution_role.arn
	repository          = var.website_repository
	env_file_bucket     = local.env_file_bucket
	container_port      = local.website.port
	container_count     = 2
	private_subnets     = module.network.private_subnets
	public_subnets      = module.network.public_subnets
	vpc_id              = module.network.vpc_id
	sg_container_access = aws_security_group.container_access.id
	sg_public_access    = aws_security_group.web_access.id
	health_check_path   = "/api/hello"
}
*/