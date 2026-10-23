#!/usr/bin/env bash
# Pre-start guard: refuses to start the stack in production with default/placeholder secrets.
#
#   ./scripts/ops/validate_env.sh
#
# Variables (read from the environment, falling back to ${APP_DIR}/.env, like docker compose):
#   APP_DIR=<repo root>   directory with the .env file
# Only enforced when ENVIRONMENT=production. Exit 0 = OK, 1 = insecure configuration.
# Wired as ExecStartPre= in autoops.service (see infra/systemd/README.md).
set -eo pipefail

APP_DIR="${APP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

log() { echo "validate_env: $*" >&2; }

# Same precedence as docker compose: process environment first, then .env.
# Reads one KEY from .env without sourcing it (values may contain spaces or '*').
env_value() {
  local name=$1 line
  if [[ -n ${!name:-} ]]; then echo "${!name}"; return; fi
  line="$(grep -E "^${name}=" "${APP_DIR}/.env" 2>/dev/null | tail -n1)" || true
  line="${line#*=}"; line="${line%\"}"; echo "${line#\"}"
}

# Placeholder values shipped in .env.example, earlier templates and docs.
DEFAULT_VALUES=(
  cambia_esta_clave
  clave_secreta_jwt_autoops
  autoops_jwt_secret_key
  autoops_password
  changeme
  change_me
  secret
  password
)

is_default() {
  local value=${1,,} d
  [[ -z $value ]] && return 0
  for d in "${DEFAULT_VALUES[@]}"; do
    [[ $value == "$d" ]] && return 0
  done
  return 1
}

environment="$(env_value ENVIRONMENT)"
if [[ ${environment,,} != production ]]; then
  log "ENVIRONMENT='${environment:-unset}': production checks skipped."
  exit 0
fi

failed=0
for name in SECRET_KEY DB_PASSWORD; do
  if is_default "$(env_value "$name")"; then
    log "ERROR: ${name} is empty or still has a default value; set a strong random one (e.g. openssl rand -hex 32)."
    failed=1
  fi
done

((failed == 0)) || { log "refusing to start with ENVIRONMENT=production."; exit 1; }
log "OK: production secrets are not defaults."
