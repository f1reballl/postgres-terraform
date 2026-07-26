resource "random_password" "readonly" {
  length  = 32
  special = true
}

resource "postgresql_role" "readonly" {
  provider = postgresql.admin

  name     = "readonly_user"
  login    = true
  password = random_password.readonly.result
}

resource "terraform_data" "revoke_public_postgres_database" {
  input = "postgres"

  provisioner "local-exec" {
    command = "docker exec task1-postgres psql --set ON_ERROR_STOP=1 -U postgres -d postgres -c 'REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;'"
  }
}

module "app_alpha" {
  source = "./modules/database-access"

  database_name = "app_alpha"
  app_role_name = "app_alpha_user"
  readonly_role = postgresql_role.readonly.name

  providers = {
    postgresql.admin  = postgresql.admin
    postgresql.target = postgresql.app_alpha
  }
}

module "app_beta" {
  source = "./modules/database-access"

  database_name = "app_beta"
  app_role_name = "app_beta_user"
  readonly_role = postgresql_role.readonly.name

  providers = {
    postgresql.admin  = postgresql.admin
    postgresql.target = postgresql.app_beta
  }
}

module "app_gamma" {
  source = "./modules/database-access"

  database_name = "app_gamma"
  app_role_name = "app_gamma_user"
  readonly_role = postgresql_role.readonly.name

  providers = {
    postgresql.admin  = postgresql.admin
    postgresql.target = postgresql.app_gamma
  }
}
