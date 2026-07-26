variable "postgres_admin_password" {
  description = "Password for the local PostgreSQL administrator created by Docker Compose."
  type        = string
  sensitive   = true
  default     = "local-root-password"
}

provider "postgresql" {
  alias    = "admin"
  host     = "127.0.0.1"
  port     = 5432
  database = "postgres"
  username = "postgres"
  password = var.postgres_admin_password
  sslmode  = "disable"
}

provider "postgresql" {
  alias    = "app_alpha"
  host     = "127.0.0.1"
  port     = 5432
  database = "app_alpha"
  username = "postgres"
  password = var.postgres_admin_password
  sslmode  = "disable"
}

provider "postgresql" {
  alias    = "app_beta"
  host     = "127.0.0.1"
  port     = 5432
  database = "app_beta"
  username = "postgres"
  password = var.postgres_admin_password
  sslmode  = "disable"
}

provider "postgresql" {
  alias    = "app_gamma"
  host     = "127.0.0.1"
  port     = 5432
  database = "app_gamma"
  username = "postgres"
  password = var.postgres_admin_password
  sslmode  = "disable"
}
