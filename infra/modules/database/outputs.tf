output "rds_endpoint" {
  description = "Endpoint de connexion à la base de données"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_db_name" {
  value = aws_db_instance.main.db_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.main.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.main.arn
}