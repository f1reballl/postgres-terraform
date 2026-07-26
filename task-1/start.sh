#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker compose -f "${script_dir}/docker-compose.yml" up -d --wait
terraform -chdir="${script_dir}/terraform" init
terraform -chdir="${script_dir}/terraform" apply -auto-approve

printf '\nTask 1 is ready. Run %s/verify.sh to verify it.\n' "${script_dir}"
