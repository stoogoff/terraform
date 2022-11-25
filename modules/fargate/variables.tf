
variable "name" {
	type        = string
	description = "The name of the service that is being created."
}

variable "aws_region" {
	type        = string
	description = "The AWS region to put the bucket into. Default to eu-west-1, which is the location of the Gitlab Runners."
	default     = "eu-west-1"
}

variable "environment" {
	type        = string
	description = "The environment this will be running. One of 'dev', 'staging', or 'production'."

	validation {
		condition     = contains(["dev", "staging", "production"], var.environment)
		error_message = "The `environment` variable must be one of 'dev', 'staging', or 'production'."
	}
}

# Container
variable "certificate" {
	type        = string
	description = "The ARN of the SSL certificate that will be used for HTTPS connections. This is managed independently of the infrastructure so must be created first."
}

variable "task_execution_role" {
	type        = string
	description = "The ARN of the role that will be used to create and run Fargate tasks."
}

variable "repository" {
	type        = string
	description = "The container repository to load the docker image from."
}

variable "env_file_bucket" {
	type        = string
	description = "The ARN of the S3 bucket where the environment file for the container is stored."
}

variable "container_port" {
	type        = number
	description = "The container port to expose when running the image."
	default     = 3000
}

variable "container_count" {
	type        = number
	description = "The number of containers to run simultaneously."
	default     = 2
}

# Health check
variable "health_check_path" {
	type        = string
	description = "The path used to check the health of the running container."
}

variable "health_check_response_code" {
	type        = string
	description = "The response code expected from the health check request."
	default     = "200"
}


# Network
variable "private_subnets" {
	type        = list(string)
	description = "Array of IDs of the public subnets available to use."
}

variable "public_subnets" {
	type        = list(string)
	description = "Array of IDs of the private subnets available to use."
}

variable "vpc_id" {
	type        = string
	description = "ID of the VPC to use."
}

# Security
variable "sg_container_access" {
	type        = string
	description = "ID of the security group for private access from the load balancer to the container."
}

variable "sg_public_access" {
	type        = string
	description = "ID of the security group for public access to the load balancer."
}
