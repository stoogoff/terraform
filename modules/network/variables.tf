
variable "vpc_name" {
  type        = string
  description = "The name of the network."
}

variable "cidr_block" {
  type        = string
  description = "IP address range within the network."
  default     = "10.0.0.0/16"
}

variable "public_cidr_block" {
  type        = list(string)
  description = "A list of IP address ranges to use for public subnets."
  default     = ["10.0.1.0/24"]
}

variable "private_cidr_block" {
  type        = list(string)
  description = "A list of IP address ranges to use for private subnets."
  default     = []
}