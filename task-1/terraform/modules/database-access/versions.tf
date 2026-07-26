terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      configuration_aliases = [
        postgresql.admin,
        postgresql.target,
      ]
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
