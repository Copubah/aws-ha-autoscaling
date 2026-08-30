output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_a" {
  value = aws_subnet.public_a.id
}

output "public_subnet_b" {
  value = aws_subnet.public_b.id
}

output "private_subnet_a" {
  value = aws_subnet.private_a.id
}

output "private_subnet_b" {
  value = aws_subnet.private_b.id
}

output "target_group_arn" {
  description = "ARN of the application load balancer target group"
  value       = aws_lb_target_group.app.arn
}

output "application_url" {
  description = "URL of the application load balancer"
  value       = "http://${aws_lb.app.dns_name}"
}
