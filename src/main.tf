
locals {
	environment     = "production"
	aws_region      = "eu-west-2"
	env_file_bucket = "arn:aws:s3:::weevolve-data/fargate/"
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

resource "aws_route53_record" "www" {
	zone_id = var.zone_id
	name    = "www.stoogoff.com"
	type    = "CNAME"
	ttl     = 300
	records = [aws_alb.couchdb.dns_name]
}

resource "aws_route53_record" "db" {
	zone_id = var.zone_id
	name    = "db.stoogoff.com"
	type    = "CNAME"
	ttl     = 300
	records = [aws_alb.couchdb.dns_name]
}
