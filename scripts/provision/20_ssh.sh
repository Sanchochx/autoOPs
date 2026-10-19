#!/usr/bin/env bash
# US-HOST-002: hardening de SSH y gestión de llaves. Idempotente.
#
#   sudo ADMIN_USER=<usuario> ADMIN_SSH_PUBKEY_FILE=<ruta.pub> ./scripts/provision/20_ssh.sh
#   sudo ADMIN_USER=<usuario> ./scripts/provision/20_ssh.sh --confirm   # tras probar el login
#
# Si la configuración cambia, arma un rollback automático (SSH_ROLLBACK_MINUTES)
# que solo se cancela con --confirm. Ver infra/ssh/README.md.
# Variables opcionales: DEPLOY_USER=autoops-deploy, DEPLOY_SSH_PUBKEY_FILE,
# DEPLOY_ALLOWED_FROM (obligatoria si hay llave de despliegue), SSH_ROLLBACK_MINUTES=5.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SSH_INFRA="${REPO_ROOT}/infra/ssh"
CONF=/etc/ssh/sshd_config.d/10-autoops.conf
BANNER=/etc/ssh/autoops-banner
STATE_DIR=/var/lib/autoops-provision/ssh
ENTRYPOINT=/usr/local/sbin/autoops-deploy-entrypoint
ROLLBACK_BIN=/usr/local/sbin/autoops-ssh-rollback
ROLLBACK_UNIT=autoops-ssh-rollback

require_root
require_var ADMIN_USER
DEPLOY_USER="${DEPLOY_USER:-autoops-deploy}"
DEPLOY_SSH_PUBKEY_FILE="${DEPLOY_SSH_PUBKEY_FILE:-}"
DEPLOY_ALLOWED_FROM="${DEPLOY_ALLOWED_FROM:-}"
SSH_ROLLBACK_MINUTES="${SSH_ROLLBACK_MINUTES:-5}"

has_systemd() { [[ -d /run/systemd/system ]]; }

reload_sshd() {
  if has_systemd && systemctl is-active --quiet ssh; then
    systemctl reload ssh
  fi
}

# --- Modo --confirm: cancela el rollback automático --------------------------
if [[ "${1:-}" == "--confirm" ]]; then
  if has_systemd; then
    systemctl stop "${ROLLBACK_UNIT}.timer" 2>/dev/null || true
    systemctl reset-failed "${ROLLBACK_UNIT}.service" 2>/dev/null || true
  fi
  rm -rf "$STATE_DIR"
  log_info "Cambio confirmado: rollback automático cancelado."
  exit 0
fi
[[ $# -eq 0 ]] || die "Argumento desconocido '$1' (solo se admite --confirm)."

require_var ADMIN_SSH_PUBKEY_FILE
[[ $SSH_ROLLBACK_MINUTES =~ ^[0-9]+$ ]] || die "SSH_ROLLBACK_MINUTES debe ser un entero."
[[ -x /usr/sbin/sshd ]] || die "openssh-server no está instalado."
id "$ADMIN_USER" >/dev/null 2>&1 || die "El usuario ${ADMIN_USER} no existe (ejecuta antes 10_users.sh)."
in_group "$ADMIN_USER" sudo || die "${ADMIN_USER} no pertenece a sudo: no se endurece SSH sin una vía de administración."
grep -Eq '^Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config \
  || die "/etc/ssh/sshd_config no incluye sshd_config.d/*.conf."
/usr/sbin/sshd -t || die "La configuración actual de sshd ya es inválida; corrígela antes."

if [[ -n $DEPLOY_SSH_PUBKEY_FILE ]]; then
  [[ -n $DEPLOY_ALLOWED_FROM ]] || die "DEPLOY_ALLOWED_FROM es obligatoria con DEPLOY_SSH_PUBKEY_FILE (restricción from=)."
  [[ $DEPLOY_ALLOWED_FROM =~ ^[0-9a-fA-F:./,]+$ ]] || die "DEPLOY_ALLOWED_FROM solo admite IP/CIDR separados por comas."
  [[ $DEPLOY_USER =~ ^[a-z_][a-z0-9_-]*$ && $DEPLOY_USER != "$ADMIN_USER" ]] || die "DEPLOY_USER inválido."
fi

# read_pubkey <archivo>: imprime la llave pública ed25519 (una línea) o aborta.
read_pubkey() {
  local file=$1 line
  [[ -r $file ]] || die "No se puede leer ${file}."
  [[ "$(grep -c . "$file")" == 1 ]] || die "${file} debe contener exactamente una llave pública."
  line="$(grep . "$file")"
  [[ $line =~ ^(ssh-ed25519|sk-ssh-ed25519@openssh\.com)[[:space:]]+[A-Za-z0-9+/=]+ ]] \
    || die "${file} no es una llave pública ed25519 (¿es la privada o de otro tipo?)."
  ssh-keygen -l -f "$file" >/dev/null || die "${file} no es una llave válida."
  printf '%s' "$line"
}

# ensure_ssh_dir <usuario>: crea ~/.ssh (700) y devuelve el home por stdout.
ensure_ssh_dir() {
  local user=$1 home
  home="$(getent passwd "$user" | cut -d: -f6)"
  install -d -o "$user" -g "$(id -gn "$user")" -m 700 "${home}/.ssh"
  printf '%s' "$home"
}

# --- CA-1: llave del admin (se añade; nunca se borran las existentes) --------
admin_key="$(read_pubkey "$ADMIN_SSH_PUBKEY_FILE")"
admin_home="$(ensure_ssh_dir "$ADMIN_USER")"
admin_auth="${admin_home}/.ssh/authorized_keys"
touch "$admin_auth"
admin_blob="$(awk '{print $2}' <<<"$admin_key")"
if ! grep -qF "$admin_blob" "$admin_auth"; then
  printf '%s\n' "$admin_key" >>"$admin_auth"
  log_change "llave ed25519 añadida a ${admin_auth}"
fi
ensure_perms "$admin_auth" "${ADMIN_USER}:$(id -gn "$ADMIN_USER")" 600
# StrictModes: sshd ignora las llaves si el home admite escritura de grupo u otros.
[[ "$(stat -c '%A' "$admin_home")" =~ ^d....-..-.$ ]] \
  || die "${admin_home} admite escritura de grupo/otros: sshd rechazaría la llave (StrictModes)."

# --- CA-3: cuenta y llave de despliegue (restringida) -------------------------
allow_users="$ADMIN_USER"
if [[ -n $DEPLOY_SSH_PUBKEY_FILE ]]; then
  deploy_key="$(read_pubkey "$DEPLOY_SSH_PUBKEY_FILE")"
  install -m 755 -o root -g root "${SSH_INFRA}/autoops-deploy-entrypoint.sh" "$ENTRYPOINT"
  if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash --comment "AutoOps CI/CD deploy" "$DEPLOY_USER"
    passwd --lock "$DEPLOY_USER" >/dev/null
    log_change "creada la cuenta de despliegue ${DEPLOY_USER} (sin contraseña, sin sudo)"
  fi
  for forbidden in sudo docker; do
    if getent group "$forbidden" >/dev/null && in_group "$DEPLOY_USER" "$forbidden"; then
      gpasswd --delete "$DEPLOY_USER" "$forbidden" >/dev/null
      log_change "${DEPLOY_USER} retirado del grupo ${forbidden}"
    fi
  done
  deploy_home="$(ensure_ssh_dir "$DEPLOY_USER")"
  deploy_group="$(id -gn "$DEPLOY_USER")"
  ensure_file "${deploy_home}/.ssh/authorized_keys" \
    "restrict,from=\"${DEPLOY_ALLOWED_FROM}\",command=\"${ENTRYPOINT}\" ${deploy_key}"
  ensure_perms "${deploy_home}/.ssh/authorized_keys" "${DEPLOY_USER}:${deploy_group}" 600
  allow_users="${ADMIN_USER} ${DEPLOY_USER}"
else
  log_info "Sin DEPLOY_SSH_PUBKEY_FILE: no se configura la llave de despliegue."
fi

# --- CA-2 / CA-1: drop-in de sshd con rollback automático ---------------------
install -m 755 -o root -g root "${SSH_INFRA}/autoops-ssh-rollback.sh" "$ROLLBACK_BIN"
ensure_file "$BANNER" "Acceso restringido a personal autorizado. La actividad es registrada."

new_conf="$(sed "s/@ALLOW_USERS@/${allow_users}/" "${SSH_INFRA}/10-autoops.conf.tpl")"
if [[ -f $CONF && "$(cat "$CONF")" == "$new_conf" ]]; then
  log_info "${CONF} ya está al día."
else
  install -d -m 700 "$STATE_DIR"
  rm -f "$STATE_DIR"/10-autoops.conf.prev "$STATE_DIR"/10-autoops.conf.absent
  if [[ -f $CONF ]]; then cp -p "$CONF" "$STATE_DIR/10-autoops.conf.prev"; else : >"$STATE_DIR/10-autoops.conf.absent"; fi
  printf '%s\n' "$new_conf" >"$CONF"
  chmod 644 "$CONF"
  if ! /usr/sbin/sshd -t; then
    "$ROLLBACK_BIN" || true
    die "La nueva configuración no valida con 'sshd -t'; se restauró la anterior."
  fi
  reload_sshd
  log_change "aplicado ${CONF} (sshd recargado; las sesiones abiertas se mantienen)"

  if has_systemd; then
    systemctl stop "${ROLLBACK_UNIT}.timer" 2>/dev/null || true
    systemctl reset-failed "${ROLLBACK_UNIT}.service" 2>/dev/null || true
    systemd-run --quiet --unit="$ROLLBACK_UNIT" --on-active="${SSH_ROLLBACK_MINUTES}m" "$ROLLBACK_BIN"
    log_warn "ROLLBACK ARMADO: en ${SSH_ROLLBACK_MINUTES} min se revertirá este cambio."
  else
    log_warn "Sin systemd: no se pudo armar el rollback automático; usa ${ROLLBACK_BIN} si hace falta."
  fi
  log_warn "1) Abre OTRA terminal y entra con tu llave.  2) Si funciona: sudo ADMIN_USER=${ADMIN_USER} $0 --confirm"
fi

log_info "20_ssh.sh finalizado."
