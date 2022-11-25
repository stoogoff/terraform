
output "loadbalancer" {
	description = "Loadbalancer data."
	value       = {
		dns    = aws_lb.lb.dns_name,
		arn    = aws_lb.lb.arn,
		suffix = aws_lb.lb.arn_suffix
	}
}

output "target_group" {
	description = "Target group data."
	value       = {
		arn    = aws_alb_target_group.tg.arn
		suffix = aws_alb_target_group.tg.arn_suffix
	}
}
