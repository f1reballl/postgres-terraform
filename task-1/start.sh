#!/usr/bin/env bash
set -euo pipefail

postgres_admin_password="local-root-password"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
terraform_dir="${script_dir}/terraform"

docker compose -f "${script_dir}/docker-compose.yml" up -d --wait
terraform -chdir="${terraform_dir}" init -input=false

terraform -chdir="${terraform_dir}" apply \
  -auto-approve \
  -input=false \
  -var="postgres_admin_password=${postgres_admin_password}"

bash "${script_dir}/verify.sh"

printf '\nTask 1 is ready and verification passed.\n'
