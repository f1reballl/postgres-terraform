output "app_alpha_password" {
  value     = module.database_access["app_alpha"].password
  sensitive = true
}

output "app_beta_password" {
  value     = module.database_access["app_beta"].password
  sensitive = true
}

output "app_gamma_password" {
  value     = module.database_access["app_gamma"].password
  sensitive = true
}

output "readonly_password" {
  value     = random_password.readonly.result
  sensitive = true
}
