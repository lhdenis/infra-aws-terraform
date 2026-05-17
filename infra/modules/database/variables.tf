variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "sg_rds_id" {
  type = string
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Nom d'utilisateur admin"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Mot de passe admin — ne jamais hardcoder, passé via variable d'environnement"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Type d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}