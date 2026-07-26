output "password" {
  value     = random_password.application.result
  sensitive = true
}
