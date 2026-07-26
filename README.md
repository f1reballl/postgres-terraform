# Local PostgreSQL Terraform Assignment

This repository contains a local-only DevOps take-home assignment for
provisioning PostgreSQL with Docker Compose and Terraform. It demonstrates
reproducible infrastructure workflows, explicit database access controls,
automated verification, and safe handling of generated credentials and local
Terraform state.

The assignment is organised by task:

- `task-1/` provisions and verifies one isolated local PostgreSQL deployment.
- `task-2/` provisions and verifies multiple independent local PostgreSQL
  deployments from configuration-derived inventory.

Each task directory contains its own prerequisites, startup, verification,
teardown, architecture, and security documentation. Follow
[`AGENTS.md`](AGENTS.md) for repository workflow requirements, including
preserving full LLM interaction logs when agents are used.
