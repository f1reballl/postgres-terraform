variable "postgres_admin_password" {
  description = "Password for the local PostgreSQL administrator created by Docker Compose."
  type        = string
  sensitive   = true
  default     = ""
}

variable "postgres_container" {
  description = "Docker container name used for local PostgreSQL permission commands."
  type        = string
  default     = "task1-postgres"
}
