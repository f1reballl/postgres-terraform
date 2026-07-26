# Task 1: Single Local PostgreSQL Deployment

Task 1 provisions one PostgreSQL deployment locally. It is independent from
Task 2 and does not create multiple deployments.

## Architecture

Docker Compose runs one PostgreSQL 16 container named `task1-postgres` and
publishes it only as `127.0.0.1:5432`. Terraform connects through that loopback
address using one default PostgreSQL provider configuration. Its reusable
`database-access` module is instantiated once for each of the three application
databases, creating the matching full-access application role. A separate
reporting role has read-only access to all three databases.

Terraform generates unique, sensitive passwords for all application and
reporting roles. The generated values are kept only in ignored local Terraform
state.

## Prerequisites

- Docker Desktop with Docker Compose v2
- Terraform 1.5 or newer
- Bash

## Startup and verification

From the repository root, run:

```bash
./task-1/start.sh
```

The script starts and health-checks PostgreSQL, initializes Terraform, applies
the local state, and runs verification. To run verification again:

```bash
./task-1/verify.sh
```

Verification confirms the expected databases and roles exist, each application
role can create and write only in its matching database, the reporting role can
read every application database but cannot write or create objects, and
PostgreSQL is bound only to localhost.

## Teardown

Destroy Terraform-managed resources and then remove the Docker volume:

```bash
terraform -chdir=task-1/terraform destroy
docker compose -f task-1/docker-compose.yml down -v
```

Terraform destroys managed databases, grants, default privileges, and state.
The shared reporting role uses `skip_drop_role = true` because PostgreSQL can
retain privilege dependencies that prevent Terraform from removing it. Removing
the Compose volume immediately afterwards deletes the complete local cluster,
including that intentionally retained role. Use this full cleanup sequence
rather than Terraform destroy alone.

## Security and local-simulation limitations

The explicit `127.0.0.1:5432:5432` Compose mapping prevents LAN and public
network access. Terraform passwords and state remain local and are ignored by
Git. The documented Compose administrator password is a local-only simulation
credential allowed by the assignment; it must not be reused elsewhere.

The PostgreSQL provider cannot address PostgreSQL's `PUBLIC` pseudo-role, so
Terraform uses narrowly scoped local `docker exec` provisioners for required
`REVOKE` statements. This is a local simulation only: it does not create cloud
account, network, or IAM boundaries.
