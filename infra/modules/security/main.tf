# Secret RDS — regroupe toutes les infos de connexion BDD
resource "aws_secretsmanager_secret" "rds" {
  name        = "${var.project_name}/${var.environment}/rds"
  description = "Credentials de connexion à la base de données RDS"

  # Délai avant suppression définitive (sécurité anti-accident)
  recovery_window_in_days = 0

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.rds_endpoint
    dbname   = var.db_name
    port     = 3306
  })
}

# -----------------------------------------------
# IAM — Rôle pour les tasks ECS (le conteneur)
# -----------------------------------------------

# Ce rôle est assumé par le conteneur lui-même (pas ECS)
# Il définit ce que l'APPLICATION peut faire sur AWS
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Policy — accès en lecture au secret RDS uniquement
resource "aws_iam_policy" "read_rds_secret" {
  name        = "${var.project_name}-read-rds-secret-${var.environment}"
  description = "Permet à ECS de lire le secret RDS dans Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds.arn
      }
    ]
  })
}

# Policy — accès S3 limité au bucket de l'application
resource "aws_iam_policy" "s3_app_access" {
  name        = "${var.project_name}-s3-access-${var.environment}"
  description = "Permet à ECS de lire/écrire dans le bucket S3 de l'application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.s3_bucket_arn
      }
    ]
  })
}

# Attacher les policies au rôle task
resource "aws_iam_role_policy_attachment" "ecs_task_secret" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.read_rds_secret.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.s3_app_access.arn
}
