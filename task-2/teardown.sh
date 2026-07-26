#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

task2_prepare_compose

if [[ -d "${task2_state_dir}" ]]; then
  terraform -chdir="${task2_terraform_dir}" init -input=false

  while IFS=$'\t' read -r deployment port; do
    state_file="$(task2_state_file "${deployment}")"
    if [[ -f "${state_file}" ]]; then
      terraform -chdir="${task2_terraform_dir}" destroy -auto-approve -input=false \
        -state="${state_file}" \
        -var="deployment_id=${deployment}" \
        -var="postgres_port=${port}" \
        -var="postgres_container=$(task2_container_name "${deployment}")"
    fi
  done < <(task2_each_deployment)
fi

docker compose -p task2 -f "${task2_compose_file}" down -v
rm -rf "${task2_state_dir}" "${task2_generated_dir}"
