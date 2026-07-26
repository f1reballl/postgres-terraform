#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ "${1:-}" == "--render-compose" ]]; then
  task2_prepare_compose
  exit 0
fi

task2_prepare_compose
mkdir -p "${task2_state_dir}"
apply_log="$(mktemp)"
trap 'rm -f "${apply_log}"' EXIT

docker compose -p task2 -f "${task2_compose_file}" up -d --wait
terraform -chdir="${task2_terraform_dir}" init -input=false

while IFS=$'\t' read -r deployment port; do
  if ! terraform -chdir="${task2_terraform_dir}" apply -auto-approve -input=false -no-color \
    -state="$(task2_state_file "${deployment}")" \
    -var="deployment_id=${deployment}" \
    -var="postgres_port=${port}" \
    -var="postgres_container=$(task2_container_name "${deployment}")" > "${apply_log}" 2>&1; then
    cat "${apply_log}" >&2
    exit 1
  fi
  echo "Applied ${deployment}."
done < <(task2_each_deployment)

"${task2_script_dir}/verify.sh"
