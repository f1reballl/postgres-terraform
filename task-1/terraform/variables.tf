variable "postgres_admin_password" {
  description = "Password for the local PostgreSQL administrator created by Docker Compose."
  type        = string
  sensitive   = true
  default     = ""
}
