
output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "ID of the created network."
}

output "vpc_arn" {
  value       = aws_vpc.vpc.arn
  description = "ARN of the created network."
}

output "gateway_id" {
  value       = aws_internet_gateway.gateway.id
  description = "ID of the internet gateway."
}

output "public_subnets" {
  value       = [for o in aws_subnet.public : o.id]
  description = "ID of the public subnets within the network."
}

output "private_subnets" {
  value       = [for o in aws_subnet.private : o.id]
  description = "ID of the private subnets within the network."
}
