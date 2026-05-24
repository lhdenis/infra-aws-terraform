# main.tf
module "networking" {
  source = "./modules/networking"

  project_name         = "mon-projet"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["eu-west-3a", "eu-west-3b"]
}

module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.networking.vpc_id
  sg_alb_id          = module.networking.sg_alb_id
  sg_ecs_id          = module.networking.sg_ecs_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
}

module "database" {
  source             = "./modules/database"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  sg_rds_id          = module.networking.sg_rds_id
  db_password        = var.db_password
}

module "security" {
  source        = "./modules/security"
  project_name  = var.project_name
  environment   = var.environment
  db_password   = var.db_password
  db_username   = "admin"
  db_name       = "appdb"
  rds_endpoint  = module.database.rds_endpoint
  s3_bucket_arn = module.database.s3_bucket_arn
}

module "monitoring" {
  source                  = "./modules/monitoring"
  project_name            = var.project_name
  environment             = var.environment
  alert_email             = var.alert_email
  ecs_cluster_name        = module.compute.ecs_cluster_name
  ecs_service_name        = module.compute.ecs_service_name
  rds_identifier          = "${var.project_name}-db-${var.environment}"
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
}

 