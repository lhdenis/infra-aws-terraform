variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "rds_endpoint" {
  type      = string
  sensitive = true
}

variable "s3_bucket_arn" {
  type = string
}
