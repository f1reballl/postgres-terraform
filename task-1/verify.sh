#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
compose_file="${script_dir}/docker-compose.yml"
terraform_dir="${script_dir}/terraform"
container_id="$(docker compose -f "${compose_file}" ps -q postgres)"

if [[ -z "${container_id}" ]]; then
  echo "PostgreSQL container is not running. Start it with ${script_dir}/start.sh." >&2
  exit 1
fi

postgresql() {
  local database="$1"
  local user="$2"
  local password="$3"
  local sql="$4"
  docker compose -f "${compose_file}" exec -T \
    -e PGPASSWORD="${password}" postgres \
    psql --no-password --set ON_ERROR_STOP=1 -h 127.0.0.1 -U "${user}" -d "${database}" -c "${sql}"
}

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    echo "Expected command to fail, but it succeeded: $*" >&2
    exit 1
  fi
}

assert_localhost_binding() {
  local bindings
  bindings="$(docker inspect --format '{{range (index .NetworkSettings.Ports "5432/tcp")}}{{.HostIp}}:{{.HostPort}} {{end}}' "${container_id}")"
  if [[ "${bindings}" != "127.0.0.1:5432 " ]]; then
    echo "Expected PostgreSQL to bind only to 127.0.0.1:5432; found: ${bindings}" >&2
    exit 1
  fi
}

assert_localhost_binding

app_alpha_password="$(terraform -chdir="${terraform_dir}" output -raw app_alpha_password)"
app_beta_password="$(terraform -chdir="${terraform_dir}" output -raw app_beta_password)"
app_gamma_password="$(terraform -chdir="${terraform_dir}" output -raw app_gamma_password)"
readonly_password="$(terraform -chdir="${terraform_dir}" output -raw readonly_password)"

declare -a databases=(app_alpha app_beta app_gamma)
declare -a users=(app_alpha_user app_beta_user app_gamma_user readonly_user)
declare -a passwords=("${app_alpha_password}" "${app_beta_password}" "${app_gamma_password}")

for database in "${databases[@]}"; do
  postgresql "${database}" postgres local-root-password \
    "CREATE TABLE IF NOT EXISTS verification_seed (id integer PRIMARY KEY, value text NOT NULL); INSERT INTO verification_seed (id, value) VALUES (1, 'seed') ON CONFLICT (id) DO NOTHING;"
done

for index in "${!databases[@]}"; do
  database="${databases[${index}]}"
  user="${users[${index}]}"
  password="${passwords[${index}]}"

  postgresql "${database}" "${user}" "${password}" \
    "CREATE TABLE IF NOT EXISTS verification_${database} (id integer PRIMARY KEY); INSERT INTO verification_${database} (id) VALUES (1) ON CONFLICT (id) DO NOTHING;"

  for other_database in "${databases[@]}"; do
    if [[ "${other_database}" != "${database}" ]]; then
      expect_failure postgresql "${other_database}" "${user}" "${password}" "SELECT 1;"
    fi
  done

  expect_failure postgresql postgres "${user}" "${password}" "SELECT 1;"
done

for database in "${databases[@]}"; do
  postgresql "${database}" readonly_user "${readonly_password}" "SELECT value FROM verification_seed WHERE id = 1;"
  expect_failure postgresql "${database}" readonly_user "${readonly_password}" "INSERT INTO verification_seed (id, value) VALUES (2, 'not allowed');"
  expect_failure postgresql "${database}" readonly_user "${readonly_password}" "CREATE TABLE verification_readonly_denied (id integer);"
done

expect_failure postgresql postgres readonly_user "${readonly_password}" "SELECT 1;"

echo "Verification passed: databases and users exist, application access is isolated, readonly access is enforced, and PostgreSQL is localhost-only."
