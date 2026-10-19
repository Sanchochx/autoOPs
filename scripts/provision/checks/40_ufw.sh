#!/usr/bin/env bash
# Verifica los controles de US-NET-001 (solo lectura). Mismas variables que 40_ufw.sh:
#
#   sudo [ADMIN_CIDR=<cidr>] [UFW_WEB_PORTS="80 443"] ./scripts/provision/checks/40_ufw.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/ufw_rules.sh"

require_root
ADMIN_CIDR="${ADMIN_CIDR:-}"
UFW_WEB_PORTS="${UFW_WEB_PORTS:-}"
validate_ufw_inputs
SSH_PORT="$(resolve_ssh_port)"

ufw_active()     { [[ "$(ufw status)" == "Status: active"* ]]; }
ufw_boot()       { grep -Eq '^ENABLED=yes' /etc/ufw/ufw.conf && systemctl is-enabled --quiet ufw; }
verbose_has()    { [[ "$(ufw status verbose)" == *"$1"* ]]; }
defaults_ok()    { verbose_has 'Default: deny (incoming), allow (outgoing), deny (routed)'; }
logging_ok()     { verbose_has 'Logging: on (low)'; }
ssh_listening()  { [[ -n "$(ss -H -ltn "sport = :${SSH_PORT}")" ]]; }
# Reglas definidas = exactamente las esperadas. Se toleran los bloqueos
# `deny from <ip>` que inserta fail2ban cuando usa banaction=ufw.
rules_exact() {
  local actual expected
  actual="$(added_ufw_rules | { grep -Ev '^ufw (insert [0-9]+ )?deny from ' || true; } | sort)"
  expected="$(expected_ufw_rules "$SSH_PORT" "$ADMIN_CIDR" $UFW_WEB_PORTS | sort)"
  [[ $actual == "$expected" ]]
}
ssh_rule_ok() {
  local added rule
  added="$(added_ufw_rules)"
  rule="$(expected_ufw_rules "$SSH_PORT" "$ADMIN_CIDR")"
  grep -qxF "$rule" <<<"$added"
}

check "ufw instalado" command -v ufw
check "UFW activo" ufw_active
check "UFW habilitado en el arranque" ufw_boot
check "política por defecto: deny incoming / allow outgoing / deny routed" defaults_ok
check "sshd escucha en ${SSH_PORT}" ssh_listening
check "SSH ${SSH_PORT}/tcp permitido con rate limit${ADMIN_CIDR:+ solo desde ${ADMIN_CIDR}}" ssh_rule_ok
check "reglas definidas = exactamente las esperadas" rules_exact
check "logging low" logging_ok

if [[ -z $UFW_WEB_PORTS ]]; then
  log_info "UFW_WEB_PORTS vacío: no se espera ningún puerto web abierto (Fase 5)."
fi
check_finish
