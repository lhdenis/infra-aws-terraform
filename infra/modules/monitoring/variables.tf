variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  description = "Email pour recevoir les alertes CloudWatch"
  type        = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "rds_identifier" {
  description = "Identifiant de l'instance RDS"
  type        = string
}

variable "alb_arn_suffix" {
  description = "Suffix ARN de l'ALB (requis par CloudWatch)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Suffix ARN du Target Group"
  type        = string
}