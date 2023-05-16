
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
		},
		{
			name         = "website"
			port         = 3000
			domain       = "www.stoogoff.com"
			zone         = var.zone_id_stoogoff
			health_check = "/api/hello"
		},
		{
			name         = "aegean"
			port         = 3001
			domain       = "www.aegeanrpg.com"
			zone         = var.zone_id_aegean
			health_check = "/api/hello"
		}
	]
}

provider "aws" {
	region = local.aws_region
}

resource "aws_route53_record" "domains" {
	count = length(local.domains)

	zone_id = local.domains[count.index].zone
	name    = local.domains[count.index].domain
	type    = "CNAME"
	ttl     = 300
	records = [aws_alb.couchdb.dns_name]
}
