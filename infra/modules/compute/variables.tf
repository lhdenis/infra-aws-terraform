variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "sg_alb_id" {
  type = string
}

variable "sg_ecs_id" {
  type = string
}

variable "container_image" {
  description = "Image Docker à déployer"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port exposé par le conteneur"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "CPU alloué à la task ECS (en units)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "RAM allouée à la task ECS (en MB)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Nombre de conteneurs souhaités"
  type        = number
  default     = 1
}