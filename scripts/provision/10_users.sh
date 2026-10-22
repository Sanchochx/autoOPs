#!/usr/bin/env bash
# US-HOST-001: native users and privilege model. Idempotent.
#
#   sudo ADMIN_USER=<user> ./scripts/provision/10_users.sh
#
# Variables: ADMIN_USER (required), SERVICE_USER=autoops, SERVICE_UID=1500,
# SERVICE_GID=1500, APP_DIR=/opt/autoops, PWQUALITY_MINLEN=14.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_root
require_var ADMIN_USER
SERVICE_USER="${SERVICE_USER:-autoops}"
SERVICE_UID="${SERVICE_UID:-1500}"
SERVICE_GID="${SERVICE_GID:-1500}"
APP_DIR="${APP_DIR:-/opt/autoops}"
PWQUALITY_MINLEN="${PWQUALITY_MINLEN:-14}"
NOLOGIN_SHELL=/usr/sbin/nologin

[[ $ADMIN_USER =~ ^[a-z_][a-z0-9_-]*$ ]] || die "ADMIN_USER '${ADMIN_USER}' no es un nombre de usuario válido."
[[ $ADMIN_USER != root && $ADMIN_USER != "$SERVICE_USER" ]] \
  || die "ADMIN_USER no puede ser root ni ${SERVICE_USER}."

# --- AC-1: admin user and locked root ---------------------------
if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash --groups sudo "$ADMIN_USER"
  log_change "creado el usuario ${ADMIN_USER}"
fi

if ! in_group "$ADMIN_USER" sudo; then
  usermod --append --groups sudo "$ADMIN_USER"
  log_change "${ADMIN_USER} añadido al grupo sudo"
fi

# AC-4: the docker group is equivalent to root; the admin operates with `sudo docker`.
if getent group docker >/dev/null && in_group "$ADMIN_USER" docker; then
  gpasswd --delete "$ADMIN_USER" docker >/dev/null
  log_change "${ADMIN_USER} retirado del grupo docker"
fi

if sudo -l -U "$ADMIN_USER" 2>/dev/null | grep -q 'NOPASSWD'; then
  log_warn "${ADMIN_USER} tiene reglas sudo NOPASSWD; revisa /etc/sudoers.d (el check lo marcará como FAIL)."
fi

# Anti-lockout safeguard: root is not locked unless an admin with a password and sudo exists.
if [[ "$(passwd_status "$ADMIN_USER")" != P ]]; then
  die "${ADMIN_USER} no tiene contraseña usable. Ejecuta 'sudo passwd ${ADMIN_USER}' y repite; no se ha bloqueado root."
fi

if [[ "$(passwd_status root)" != L ]]; then
  passwd --lock root >/dev/null
  log_change "contraseña de root bloqueada"
fi

# --- AC-2: service user without login --------------------------------------
if getent group "$SERVICE_USER" >/dev/null; then
  [[ "$(getent group "$SERVICE_USER" | cut -d: -f3)" == "$SERVICE_GID" ]] \
    || die "El grupo ${SERVICE_USER} existe con un GID distinto de ${SERVICE_GID}."
else
  [[ -z "$(getent group "$SERVICE_GID")" ]] || die "El GID ${SERVICE_GID} ya está en uso."
  groupadd --gid "$SERVICE_GID" "$SERVICE_USER"
  log_change "creado el grupo ${SERVICE_USER} (GID ${SERVICE_GID})"
fi

if getent passwd "$SERVICE_USER" >/dev/null; then
  [[ "$(id -u "$SERVICE_USER")" == "$SERVICE_UID" ]] \
    || die "El usuario ${SERVICE_USER} existe con un UID distinto de ${SERVICE_UID}."
  if [[ "$(getent passwd "$SERVICE_USER" | cut -d: -f7)" != "$NOLOGIN_SHELL" ]]; then
    usermod --shell "$NOLOGIN_SHELL" "$SERVICE_USER"
    log_change "shell de ${SERVICE_USER} -> ${NOLOGIN_SHELL}"
  fi
else
  [[ -z "$(getent passwd "$SERVICE_UID")" ]] || die "El UID ${SERVICE_UID} ya está en uso."
  useradd --system --uid "$SERVICE_UID" --gid "$SERVICE_GID" \
    --home-dir "$APP_DIR" --no-create-home --shell "$NOLOGIN_SHELL" "$SERVICE_USER"
  log_change "creado el usuario de servicio ${SERVICE_USER} (UID ${SERVICE_UID})"
fi

if [[ "$(passwd_status "$SERVICE_USER")" != L ]]; then
  passwd --lock "$SERVICE_USER" >/dev/null
  log_change "contraseña de ${SERVICE_USER} bloqueada"
fi

if [[ ! -d $APP_DIR ]]; then
  install --directory --owner="$SERVICE_USER" --group="$SERVICE_USER" --mode=750 "$APP_DIR"
  log_change "creado ${APP_DIR}"
fi
ensure_perms "$APP_DIR" "${SERVICE_USER}:${SERVICE_USER}" 750

# --- AC-3: secrets, umask and password policy -------------------------
if [[ -f $APP_DIR/.env ]]; then
  ensure_perms "$APP_DIR/.env" "${SERVICE_USER}:${SERVICE_USER}" 600
else
  log_info "${APP_DIR}/.env aún no existe: al desplegarlo debe quedar ${SERVICE_USER}:${SERVICE_USER} 0600."
fi

# Umask 027 for login sessions (pam_umask reads it from login.defs). The service
# process gets it from the systemd unit (UMask=0027, US-SYS-003).
if grep -Eq '^UMASK[[:space:]]+027$' /etc/login.defs; then
  :
elif grep -Eq '^UMASK[[:space:]]' /etc/login.defs; then
  sed -i -E 's/^UMASK[[:space:]]+.*/UMASK\t\t027/' /etc/login.defs
  log_change "UMASK 027 en /etc/login.defs"
else
  printf 'UMASK\t\t027\n' >>/etc/login.defs
  log_change "UMASK 027 añadido a /etc/login.defs"
fi

if ! dpkg -s libpam-pwquality >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y libpam-pwquality >/dev/null
  log_change "instalado libpam-pwquality"
fi
install -d -m 755 /etc/security/pwquality.conf.d
ensure_file /etc/security/pwquality.conf.d/10-autoops.conf "# Gestionado por scripts/provision/10_users.sh
minlen = ${PWQUALITY_MINLEN}
minclass = 3
maxrepeat = 3
dictcheck = 1
enforce_for_root"

log_info "10_users.sh finalizado."
