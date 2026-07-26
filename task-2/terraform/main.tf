locals {
  applications = {
    app_alpha = "app_alpha_user"
    app_beta  = "app_beta_user"
    app_gamma = "app_gamma_user"
  }
}

resource "random_password" "readonly" {
  length  = 32
  special = true
}

resource "postgresql_role" "readonly" {
  name     = "readonly_user"
  login    = true
  password = random_password.readonly.result
}

resource "terraform_data" "revoke_public_postgres_database" {
  input            = var.deployment_id
  triggers_replace = [var.postgres_container]

  provisioner "local-exec" {
    command = "docker exec ${var.postgres_container} psql --set ON_ERROR_STOP=1 -U postgres -d postgres -c 'REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;'"
  }
}

module "database_access" {
  source = "./modules/database-access"

  for_each = local.applications

  database_name      = each.key
  app_role_name      = each.value
  readonly_role      = postgresql_role.readonly.name
  postgres_container = var.postgres_container
}
