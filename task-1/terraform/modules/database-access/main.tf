resource "random_password" "application" {
  length  = 32
  special = true
}

resource "postgresql_role" "application" {
  provider = postgresql.admin

  name     = var.app_role_name
  login    = true
  password = random_password.application.result
}

resource "postgresql_database" "application" {
  provider = postgresql.admin

  name  = var.database_name
  owner = "postgres"
}

resource "terraform_data" "revoke_public_database" {
  input = postgresql_database.application.name

  provisioner "local-exec" {
    command = "docker exec task1-postgres psql --set ON_ERROR_STOP=1 -U postgres -d postgres -c 'REVOKE CONNECT ON DATABASE ${postgresql_database.application.name} FROM PUBLIC;'"
  }
}

resource "postgresql_grant" "application_database" {
  provider = postgresql.admin

  database    = postgresql_database.application.name
  role        = postgresql_role.application.name
  object_type = "database"
  privileges  = ["CONNECT", "TEMPORARY"]

  depends_on = [terraform_data.revoke_public_database]
}

resource "postgresql_grant" "readonly_database" {
  provider = postgresql.admin

  database    = postgresql_database.application.name
  role        = var.readonly_role
  object_type = "database"
  privileges  = ["CONNECT"]

  depends_on = [terraform_data.revoke_public_database]
}

resource "terraform_data" "revoke_public_schema" {
  input = postgresql_database.application.name

  provisioner "local-exec" {
    command = "docker exec task1-postgres psql --set ON_ERROR_STOP=1 -U postgres -d ${postgresql_database.application.name} -c 'REVOKE ALL ON SCHEMA public FROM PUBLIC;'"
  }

  depends_on = [postgresql_grant.application_database]
}

resource "postgresql_grant" "application_schema" {
  provider = postgresql.target

  database    = postgresql_database.application.name
  role        = postgresql_role.application.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]

  depends_on = [terraform_data.revoke_public_schema]
}

resource "postgresql_grant" "readonly_schema" {
  provider = postgresql.target

  database    = postgresql_database.application.name
  role        = var.readonly_role
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]

  depends_on = [postgresql_grant.application_schema]
}

resource "postgresql_default_privileges" "readonly_tables" {
  provider = postgresql.target

  database    = postgresql_database.application.name
  owner       = "postgres"
  role        = var.readonly_role
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [postgresql_grant.readonly_schema]
}

resource "postgresql_default_privileges" "readonly_application_tables" {
  provider = postgresql.target

  database    = postgresql_database.application.name
  owner       = postgresql_role.application.name
  role        = var.readonly_role
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [postgresql_grant.application_schema]
}
