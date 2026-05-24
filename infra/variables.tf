variable "aws_region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "project_name" {
  description = "Nom du projet (utilisé pour les tags et noms de ressources)"
  type        = string
  default     = "mon-projet"
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "db_password" {
  description = "Mot de passe admin — ne jamais hardcoder, passé via variable d'environnement"
  type        = string
  sensitive   = true
}

variable "alert_email" {
  description = "Email pour les alertes CloudWatch"
  type        = string
}