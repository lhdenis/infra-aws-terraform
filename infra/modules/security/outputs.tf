output "ecs_task_role_arn" {
  description = "ARN du rôle IAM assumé par les conteneurs ECS"
  value       = aws_iam_role.ecs_task.arn
}

output "rds_secret_arn" {
  description = "ARN du secret RDS dans Secrets Manager"
  value       = aws_secretsmanager_secret.rds.arn
  sensitive   = true
}
