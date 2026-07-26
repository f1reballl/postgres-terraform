# Task 2: Multiple Local PostgreSQL Deployments

Task 2 simulates 15 independent cloud-account deployments on one local
machine. It does not modify or depend on the running Task 1 deployment.

## Architecture

`lib.sh` derives deployments from `DEPLOYMENT_COUNT` (default `15`) and
`POSTGRES_BASE_PORT` (default `15432`). It creates identifiers
`deployment-01` through `deployment-15` and maps them to consecutive ports
`15432` through `15446`. `start.sh` renders a local Docker Compose
configuration from those settings, starts one PostgreSQL container per derived
deployment, then runs the same generic Terraform root once per deployment.
Terraform uses a single default PostgreSQL provider configuration; the runner
supplies the target port and stores state at
`.state/<deployment>.tfstate`.

Each state file is the local equivalent of a separate cloud-account Terraform
backend. The reusable `database-access` module provisions three application
databases with matching owner roles, plus a reporting role with read access to
all three. Separate Terraform state executions generate separate passwords.

## Prerequisites

- Docker Desktop with Docker Compose v2
- Terraform 1.5 or newer
- Bash and the standard macOS `shasum` utility

## Startup and verification

From the repository root, run:

```bash
./task-2/start.sh
```

The script renders the Compose file, starts and health-checks all 15 instances,
initializes Terraform, applies a separate state for every deployment, and runs
the full verification suite. To run verification again:

```bash
./task-2/verify.sh
```

Verification checks the 15-instance count, health, exact localhost bindings,
databases and roles, application-user isolation, reporting-user read-only
access, and that all generated credentials are distinct across deployments.

## Add deployment 16

Run:

```bash
DEPLOYMENT_COUNT=16 ./task-2/start.sh
```

This derives `deployment-16` on port `15447` without provider aliases, copied
Terraform roots, or per-deployment application definitions. Set
`POSTGRES_BASE_PORT` too when the default port range conflicts locally.

## Teardown

The following destroys each Terraform state, removes all Task 2 containers and
volumes, and removes generated local state and Compose files:

```bash
./task-2/teardown.sh
```

Terraform destroys managed databases, grants, default privileges, and state.
The shared read-only role uses `skip_drop_role = true` because PostgreSQL can
retain privilege dependencies that prevent its removal. The subsequent Compose
volume deletion removes the complete local cluster, including that intentionally
retained role. Use this full teardown rather than Terraform destroy alone.

## Security and local-simulation limitations

Every Compose port is explicitly published as `127.0.0.1:<port>:5432`; no
database is LAN or public-network reachable. Application and reporting
passwords are Terraform-generated sensitive values stored only in ignored
local state. The documented Compose administrator password is a local-only
simulation credential permitted by the assignment and must not be reused.

The PostgreSQL provider cannot address PostgreSQL's `PUBLIC` pseudo-role, so
Terraform uses narrowly scoped local `docker exec` provisioners for the
required `REVOKE` statements. Docker containers and per-file local state are
only a simulation of account isolation: they do not create real cloud account,
network, or IAM boundaries.
