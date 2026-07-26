# Local PostgreSQL Terraform Assignment

Task 1 provides one local PostgreSQL deployment. It intentionally does not
implement the assignment's multi-deployment task.

## Prerequisites

- Docker Desktop (Docker Compose v2)
- Terraform 1.5 or newer
- Bash

## Startup and verification

From the repository root, run the single startup command:

```bash
./task-1/start.sh
```

This starts PostgreSQL at `127.0.0.1:5432`, initializes Terraform providers,
and applies the local Terraform state in `task-1/terraform/`. Then run:

```bash
./task-1/verify.sh
```

The verification script proves the databases and users exist by authenticating
as each role. It verifies application users can create and write only in their
matching database, the read-only user can select from every database but cannot
insert or create tables, and Docker publishes PostgreSQL only on localhost.

## Teardown

Destroy the Terraform-managed roles and databases, then remove the local
container and data volume:

```bash
terraform -chdir=task-1/terraform destroy
docker compose -f task-1/docker-compose.yml down -v
```

## Architecture and security assumptions

Docker Compose runs PostgreSQL in one local container with an explicit
`127.0.0.1:5432:5432` port mapping. Terraform uses the PostgreSQL provider over
that loopback connection and a reusable `database-access` module once per
application database. The module generates a unique 32-character password for
each application role; Terraform generates a fourth password for the shared
read-only role. Those generated values are sensitive outputs stored only in the
ignored local Terraform state.

The PostgreSQL provider cannot revoke privileges from PostgreSQL's `PUBLIC`
pseudo-role directly, so the reusable module uses Terraform's local provisioner
to execute those narrowly scoped `REVOKE` commands inside the local container.

The Docker Compose administrator password is intentionally a documented local
simulation credential, as allowed by the assignment. It must not be reused
outside this local exercise. No remote Terraform state, cloud service, or
external environment is used.
