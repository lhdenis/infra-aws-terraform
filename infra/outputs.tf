output "alb_dns_name" {
  description = "URL publique de l'application"
  value       = module.compute.alb_dns_name
}

output "cloudwatch_dashboard_url" {
  description = "URL du dashboard CloudWatch"
  value       = module.monitoring.dashboard_url
}

output "rds_secret_arn" {
  description = "ARN du secret RDS dans Secrets Manager"
  value       = module.security.rds_secret_arn
  sensitive   = true
}

output "vpc_id" {
  description = "vpc crée dans aws"
  value       = module.networking.vpc_id
}