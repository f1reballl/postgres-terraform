#!/usr/bin/env bash

task2_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_COUNT="${DEPLOYMENT_COUNT:-15}"
POSTGRES_BASE_PORT="${POSTGRES_BASE_PORT:-15432}"
task2_generated_dir="${task2_script_dir}/.generated"
task2_compose_file="${task2_generated_dir}/docker-compose.yml"
task2_state_dir="${task2_script_dir}/.state"
task2_terraform_dir="${task2_script_dir}/terraform"

task2_each_deployment() {
  local index deployment port

  if [[ ! "${DEPLOYMENT_COUNT}" =~ ^[1-9][0-9]*$ ]] || [[ ! "${POSTGRES_BASE_PORT}" =~ ^[0-9]+$ ]]; then
    echo "DEPLOYMENT_COUNT must be a positive integer and POSTGRES_BASE_PORT must be numeric." >&2
    return 1
  fi

  if (( POSTGRES_BASE_PORT < 1 || POSTGRES_BASE_PORT + DEPLOYMENT_COUNT - 1 > 65535 )); then
    echo "Derived PostgreSQL ports must be between 1 and 65535." >&2
    return 1
  fi

  for ((index = 1; index <= DEPLOYMENT_COUNT; index++)); do
    printf -v deployment 'deployment-%02d' "${index}"
    port=$((POSTGRES_BASE_PORT + index - 1))
    printf '%s\t%s\n' "${deployment}" "${port}"
  done
}

task2_prepare_compose() {
  local deployment port temporary_file

  mkdir -p "${task2_generated_dir}"
  temporary_file="${task2_compose_file}.tmp"
  printf 'services:\n' > "${temporary_file}"

  while IFS=$'\t' read -r deployment port; do
    printf '%s\n' \
      "  ${deployment}:" \
      "    container_name: task2-${deployment}" \
      "    image: postgres:16-alpine" \
      "    environment:" \
      "      POSTGRES_USER: postgres" \
      "      POSTGRES_PASSWORD: local-root-password" \
      "      POSTGRES_DB: postgres" \
      "    ports:" \
      "      - \"127.0.0.1:${port}:5432\"" \
      "    volumes:" \
      "      - ${deployment}_data:/var/lib/postgresql/data" \
      "    healthcheck:" \
      "      test: [\"CMD-SHELL\", \"pg_isready -U postgres -d postgres\"]" \
      "      interval: 2s" \
      "      timeout: 3s" \
      "      retries: 15" >> "${temporary_file}"
  done < <(task2_each_deployment)

  printf '\nvolumes:\n' >> "${temporary_file}"
  while IFS=$'\t' read -r deployment port; do
    printf '  %s_data:\n' "${deployment}" >> "${temporary_file}"
  done < <(task2_each_deployment)

  mv "${temporary_file}" "${task2_compose_file}"
}

task2_state_file() {
  local deployment="$1"
  printf '%s/%s.tfstate' "${task2_state_dir}" "${deployment}"
}

task2_container_name() {
  local deployment="$1"
  printf 'task2-%s' "${deployment}"
}
