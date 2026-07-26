# Task 2: Multiple Local PostgreSQL Deployments

Task 2 simulates 15 independent cloud-account deployments on one local
machine. It does not modify or depend on the running Task 1 deployment.

## Architecture

`deployments.tsv` is the complete deployment inventory. Each row supplies an
independent deployment identifier and a distinct localhost port. `start.sh`
renders a local Docker Compose configuration from that inventory, starts one
PostgreSQL container per row, then runs the same generic Terraform root once
per row. Terraform uses a single default PostgreSQL provider configuration;
the runner supplies the target port and stores state at
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

Add one tab-separated row to `task-2/deployments.tsv` with a unique identifier
and unused port, for example:

```text
deployment-16	15447
```

Then rerun `./task-2/start.sh`. No provider aliases, copied Terraform roots,
or per-deployment application definitions are required.

## Teardown

The following destroys each Terraform state, removes all Task 2 containers and
volumes, and removes generated local state and Compose files:

```bash
./task-2/teardown.sh
```

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
