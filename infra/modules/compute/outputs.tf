output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.main.arn_suffix
}

output "alb_dns_name" {
  description = "DNS public de l'ALB pour accéder à l'application"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.main.name
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.ecs.name
}