
locals {
	environment     = "production"
	aws_region      = "eu-west-2"
	env_file_bucket = "arn:aws:s3:::weevolve-data/fargate/"
	task_name       = "container-role"
	couch_instance  = "t3.micro"
	couch_ami       = "ami-0114eaef9a5a23d30"

	domains = [
		{
			name       	 = "couchdb"
			port       	 = 5984
			domain       = "db.stoogoff.com"
			zone         = var.zone_id_stoogoff
			health_check = "/"
			exclude_dns  = false
		},
		{
			name         = "website"
			port         = 3000
			domain       = "www.stoogoff.com"
			zone         = var.zone_id_stoogoff
			health_check = "/api/hello"
			exclude_dns  = false
		},
		{
			name         = "aegean"
			port         = 3001
			domain       = "www.aegeanrpg.com"
			zone         = var.zone_id_aegean
			health_check = "/api/hello"
			exclude_dns  = false
		},
		{
			name         = "weevolve"
			port         = 3002
			domain       = "we-evolve.co.uk"
			zone         = var.zone_id_weevolve
			health_check = "/api/hello"
			exclude_dns  = true
		}
	]
}

provider "aws" {
	region = local.aws_region
}

resource "aws_route53_record" "domains" {
	for_each = {
		for index, domain in local.domains : domain.domain => domain
		if domain.exclude_dns != true
	}

	zone_id = each.value.zone
	name    = each.value.domain
	type    = "CNAME"
	ttl     = 300
	records = [aws_alb.couchdb.dns_name]
}
