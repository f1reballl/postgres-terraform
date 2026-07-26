variable "deployment_id" {
  description = "Identifier for the independent local deployment."
  type        = string
}

variable "postgres_port" {
  description = "Localhost port published by the deployment's PostgreSQL container."
  type        = number
}

variable "postgres_container" {
  description = "Container name used for narrowly scoped PUBLIC privilege revocations."
  type        = string
}

variable "postgres_admin_password" {
  description = "Local simulation administrator password configured by Docker Compose."
  type        = string
  sensitive   = true
  default     = "local-root-password"
}
