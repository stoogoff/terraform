
variable "certificate_euwest1" {
	type        = string
	description = "The ARN of the SSL certificate that will be used for HTTPS connections. This is managed independently of the infrastructure so must be created first."
}

variable "certificate_useast1" {
	type        = string
	description = "The ARN of the SSL certificate that will be used for HTTPS connections. This is managed independently of the infrastructure so must be created first."
}

variable "website_repository" {
	type        = string
	description = "The container repository to load the website image from."
}

variable "zone_id" {
	type        = string
	description = "DNS Zone ID to attach subdomains to."
}

variable "db_password" {
	type        = string
	description = "Database password for the docker script."
}

variable "cdn_bucket_name" {
	type        = string
	description = "Name for S3 bucket which hosts the CDN content."
}
