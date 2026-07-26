provider "postgresql" {
  host     = "127.0.0.1"
  port     = 5432
  database = "postgres"
  username = "postgres"
  password = var.postgres_admin_password
  sslmode  = "disable"
}
