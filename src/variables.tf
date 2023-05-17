
variable "certificate_euwest1" {
	type        = string
	description = "The ARN of the SSL certificate that will be used for HTTPS connections. This is managed independently of the infrastructure so must be created first."
}

variable "certificate_useast1" {
	type        = string
	description = "The ARN of the SSL certificate that will be used for HTTPS connections. This is managed independently of the infrastructure so must be created first."
}

variable "zone_id_stoogoff" {
	type        = string
	description = "DNS Zone ID to attach subdomains to."
}

variable "zone_id_aegean" {
	type        = string
	description = "DNS Zone ID to attach subdomains to."
}

variable "db_password" {
	type        = string
	description = "Database password for the docker script."
}

