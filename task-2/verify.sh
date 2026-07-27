#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

task2_prepare_compose

expected_count="$(task2_each_deployment | wc -l | tr -d ' ')"
running_count="$(docker compose -p task2 -f "${task2_compose_file}" ps --services --status running | wc -l | tr -d ' ')"

if [[ "${running_count}" != "${expected_count}" ]]; then
  echo "Expected ${expected_count} healthy PostgreSQL services; found ${running_count} running." >&2
  exit 1
fi

postgresql() {
  local container="$1"
  local database="$2"
  local user="$3"
  local password="$4"
  local sql="$5"
  docker exec -e PGPASSWORD="${password}" "${container}" \
    psql --no-password --set ON_ERROR_STOP=1 -h 127.0.0.1 -U "${user}" -d "${database}" -c "${sql}"
}

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    echo "Expected command to fail, but it succeeded: $*" >&2
    exit 1
  fi
}

password_hashes_file="$(mktemp)"
trap 'rm -f "${password_hashes_file}"' EXIT

while IFS=$'\t' read -r deployment port; do
  container="$(task2_container_name "${deployment}")"
  container_id="$(docker compose -p task2 -f "${task2_compose_file}" ps -q "${deployment}")"
  binding="$(docker inspect --format '{{range (index .NetworkSettings.Ports "5432/tcp")}}{{.HostIp}}:{{.HostPort}}{{end}}' "${container_id}")"

  if [[ "${binding}" != "127.0.0.1:${port}" ]]; then
    echo "${deployment} is not localhost-only on its configured port: ${binding}" >&2
    exit 1
  fi

  app_alpha_password="$(terraform -chdir="${task2_terraform_dir}" output -state="$(task2_state_file "${deployment}")" -raw app_alpha_password)"
  app_beta_password="$(terraform -chdir="${task2_terraform_dir}" output -state="$(task2_state_file "${deployment}")" -raw app_beta_password)"
  app_gamma_password="$(terraform -chdir="${task2_terraform_dir}" output -state="$(task2_state_file "${deployment}")" -raw app_gamma_password)"
  readonly_password="$(terraform -chdir="${task2_terraform_dir}" output -state="$(task2_state_file "${deployment}")" -raw readonly_password)"

  for password in "${app_alpha_password}" "${app_beta_password}" "${app_gamma_password}" "${readonly_password}"; do
    password_hash="$(printf %s "${password}" | LC_ALL=C shasum -a 256 | awk '{print $1}')"
    if grep -Fxq "${password_hash}" "${password_hashes_file}"; then
      echo "Generated credentials are not unique across deployments." >&2
      exit 1
    fi
    printf '%s\n' "${password_hash}" >> "${password_hashes_file}"
  done

  declare -a databases=(app_alpha app_beta app_gamma)
  declare -a users=(app_alpha_user app_beta_user app_gamma_user)
  declare -a passwords=("${app_alpha_password}" "${app_beta_password}" "${app_gamma_password}")

  for index in "${!databases[@]}"; do
    database="${databases[${index}]}"
    user="${users[${index}]}"
    password="${passwords[${index}]}"

    postgresql "${container}" "${database}" "${user}" "${password}" \
      "CREATE TABLE IF NOT EXISTS verification_seed (id integer PRIMARY KEY, value text NOT NULL); INSERT INTO verification_seed (id, value) VALUES (1, 'seed') ON CONFLICT (id) DO NOTHING;"

    for other_database in "${databases[@]}"; do
      if [[ "${other_database}" != "${database}" ]]; then
        expect_failure postgresql "${container}" "${other_database}" "${user}" "${password}" "SELECT 1;"
      fi
    done
  done

  for database in "${databases[@]}"; do
    postgresql "${container}" "${database}" readonly_user "${readonly_password}" "SELECT value FROM verification_seed WHERE id = 1;"
    expect_failure postgresql "${container}" "${database}" readonly_user "${readonly_password}" "INSERT INTO verification_seed (id, value) VALUES (2, 'not allowed');"
    expect_failure postgresql "${container}" "${database}" readonly_user "${readonly_password}" "CREATE TABLE verification_readonly_denied (id integer);"
  done

  echo "Verified ${deployment} on 127.0.0.1:${port}."
done < <(task2_each_deployment)

echo "Verification passed for all ${expected_count} isolated deployments."
