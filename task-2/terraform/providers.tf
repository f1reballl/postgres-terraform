provider "postgresql" {
  host     = "127.0.0.1"
  port     = var.postgres_port
  database = "postgres"
  username = "postgres"
  password = var.postgres_admin_password
  sslmode  = "disable"
}
