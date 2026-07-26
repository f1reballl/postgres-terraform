output "app_alpha_password" {
  value     = module.app_alpha.password
  sensitive = true
}

output "app_beta_password" {
  value     = module.app_beta.password
  sensitive = true
}

output "app_gamma_password" {
  value     = module.app_gamma.password
  sensitive = true
}

output "readonly_password" {
  value     = random_password.readonly.result
  sensitive = true
}
