
variable "certificate" {
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