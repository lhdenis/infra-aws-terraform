# VPC principal
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Subnets publics (un par AZ)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet-public-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Subnets privés (un par AZ)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-subnet-private-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Internet Gateway — permet au trafic internet d'entrer dans le VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route table publique — dirige le trafic vers l'Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-rt-public-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Association subnets publics <-> route table publique
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group — ALB (load balancer)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb-${var.environment}"
  description = "Autorise le trafic HTTP/HTTPS entrant depuis internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg-alb-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group — ECS (conteneurs)
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-sg-ecs-${var.environment}"
  description = "Autorise le trafic entrant uniquement depuis l'ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg-ecs-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group — RDS (base de données)
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds-${var.environment}"
  description = "Autorise le trafic MySQL uniquement depuis ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = {
    Name        = "${var.project_name}-sg-rds-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}
