# Secrets Manager for Database Credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.environment}-${var.project_name}-db-credentials"
  description = "Database credentials for ${var.project_name} ${var.environment} environment"
  recovery_window_in_days = var.recovery_window_in_days

  lifecycle {
    prevent_destroy = true
  }
  tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-db-credentials"
    }
  )
}

# Store database credentials in secret
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine = "Postgres"
    host = var.db_host
    port = var.db_port
    dbname =var.db_name
  })
}