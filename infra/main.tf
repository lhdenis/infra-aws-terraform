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
  source = "./modules/compute"

  # project_name      = "mon-projet"
  # environment       = "dev"
  # aws_region        = var.aws_region
  # vpc_id            = module.networking.vpc_id
  # public_subnet_ids = module.networking.public_subnet_ids
  # private_subnet_ids = module.networking.private_subnet_ids
  # sg_alb_id         = module.networking.sg_alb_id
  # sg_ecs_id         = module.networking.sg_ecs_id
  # container_image   = "nginx:latest"
  # container_port    = 80
  # task_cpu          = 256
  # task_memory       = 512
  # desired_count     = 1
}
