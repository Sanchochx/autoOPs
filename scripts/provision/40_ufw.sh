#!/usr/bin/env bash
# US-NET-001: firewall UFW con política deny-by-default. Idempotente.
#
#   sudo ./scripts/provision/40_ufw.sh
#
# Variables (todas opcionales):
#   SSH_PORT       puerto SSH a permitir; por defecto, el efectivo de sshd (`sshd -T`)
#   ADMIN_CIDR     restringe SSH a esta IP/CIDR; vacío = SSH abierto a cualquier origen (con rate limit)
#   UFW_WEB_PORTS  puertos TCP web a abrir, separados por espacios (ej. "80 443"); por defecto, ninguno
#   UFW_DRY_RUN=1  muestra las reglas que aplicaría y sale sin tocar el firewall
#
# SEGURIDAD ANTI-BLOQUEO: la regla SSH se añade y se verifica ANTES de habilitar UFW,
# y el script se niega a habilitarlo si sshd no escucha en el puerto indicado.
# UFW no filtra los puertos publicados por Docker (se resuelve en US-NET-002).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ufw_rules.sh"

require_root
ADMIN_CIDR="${ADMIN_CIDR:-}"
UFW_WEB_PORTS="${UFW_WEB_PORTS:-}"
validate_ufw_inputs
SSH_PORT="$(resolve_ssh_port)"

# --- Guardas anti-bloqueo (antes de tocar nada) ---------------------------------
[[ -n "$(ss -H -ltn "sport = :${SSH_PORT}")" ]] \
  || die "Nada escucha en el puerto ${SSH_PORT}: habilitar UFW cortaría el acceso. Revisa SSH_PORT."
if [[ -n $ADMIN_CIDR && -n ${SSH_CONNECTION:-} ]]; then
  client_ip="${SSH_CONNECTION%% *}"
  python3 -I -c '
import ipaddress, sys
sys.exit(0 if ipaddress.ip_address(sys.argv[1]) in ipaddress.ip_network(sys.argv[2], strict=False) else 1)
' "$client_ip" "$ADMIN_CIDR" \
    || die "Tu sesión SSH actual (${client_ip}) no está en ADMIN_CIDR=${ADMIN_CIDR}: te quedarías sin acceso nuevo."
fi

mapfile -t wanted < <(expected_ufw_rules "$SSH_PORT" "$ADMIN_CIDR" $UFW_WEB_PORTS)
if [[ ${UFW_DRY_RUN:-0} == 1 ]]; then
  log_info "DRY RUN: se aplicaría deny incoming / allow outgoing / deny routed, logging low y:"
  printf '  %s\n' "${wanted[@]}"
  exit 0
fi

# --- Instalación ------------------------------------------------------------------
if ! command -v ufw >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq ufw
  log_change "instalado ufw"
fi

was_active=0
[[ "$(ufw status)" == "Status: active"* ]] && was_active=1
before="$(added_ufw_rules | sort)"

# --- CA-1: políticas por defecto y SSH (ANTES de habilitar) --------------------------
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw default deny routed >/dev/null

if [[ -n $ADMIN_CIDR ]]; then
  ufw limit from "$ADMIN_CIDR" to any port "$SSH_PORT" proto tcp comment 'autoops: ssh' >/dev/null
else
  ufw limit "${SSH_PORT}/tcp" comment 'autoops: ssh' >/dev/null
fi

# --- CA-2: puertos web (opt-in; por defecto ninguno) ---------------------------------
for port in $UFW_WEB_PORTS; do
  ufw allow "${port}/tcp" comment 'autoops: web' >/dev/null
done

# --- CA-3: logging a journald/kernel ----------------------------------------------------
ufw logging low >/dev/null

# Verifica que la regla SSH existe antes de habilitar; si no, aborta.
added_now="$(added_ufw_rules)"
grep -qxF "${wanted[0]}" <<<"$added_now" \
  || die "La regla SSH '${wanted[0]}' no quedó registrada; UFW NO se habilita para no bloquearte."

if ((!was_active)); then
  ufw --force enable >/dev/null
  log_change "UFW habilitado (SSH ${SSH_PORT}/tcp ya permitido)"
fi
[[ -d /run/systemd/system ]] && systemctl enable ufw >/dev/null 2>&1 || true

after="$(added_ufw_rules | sort)"
[[ $before == "$after" ]] || log_change "reglas UFW actualizadas"

if [[ -z $ADMIN_CIDR ]]; then
  log_warn "SSH abierto a cualquier origen (con rate limit). Define ADMIN_CIDR para restringirlo."
fi
log_warn "UFW no filtra puertos publicados por Docker (US-NET-002). Si ya usas banaction=nftables, vuelve a ejecutar 30_fail2ban.sh para pasar a 'ufw'."
ufw status verbose
log_info "40_ufw.sh finalizado."
