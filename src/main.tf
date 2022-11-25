
locals {
	environment     = "production"
	aws_region      = "eu-west-2"
	env_file_bucket = "arn:aws:s3:::weevolve-data/fargate"
	task_name       = "container-role"

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


/*
# Mainframe set up using Fargate and an ALB
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