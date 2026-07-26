locals {
  applications = {
    app_alpha = "app_alpha_user"
    app_beta  = "app_beta_user"
    app_gamma = "app_gamma_user"
  }
}

##############################################################################
########## Creates the shared reporting user #################################
##############################################################################
resource "random_password" "readonly" {
  length  = 32
  special = true
}

resource "postgresql_role" "readonly" {
  name           = "readonly_user"
  login          = true
  password       = random_password.readonly.result
  skip_drop_role = true
}

##############################################################################
########## Creates databases/users from local.applications ###################
##############################################################################

module "database_access" {
  source = "./modules/database-access"

  for_each = local.applications

  database_name = each.key
  app_role_name = each.value
  readonly_role = postgresql_role.readonly.name
}
