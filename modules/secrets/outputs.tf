output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
  description = "ARN of the Database credentials secret"
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.db_credentials.name
  description = "Name of Database credentials secrets"
}