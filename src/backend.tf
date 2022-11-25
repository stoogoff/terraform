
terraform {
	backend "s3" {
		bucket = "weevolve-data"
		region = "eu-west-2"
		key    = "terraform/stoogoff"
	}
}