output "lb_dns_name" {
  description = "DNS name of the main network load balancer."
  value       = aws_lb.main.dns_name
}

output "lb_id" {
  description = "ID of the main network load balancer."
  value       = aws_lb.main.id
}

output "lb_arn_suffix" {
  description = "ARN suffix used for CW metrics, from the main load balancer."
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn" {
  value = aws_lb_target_group.main_target_group.arn
}



