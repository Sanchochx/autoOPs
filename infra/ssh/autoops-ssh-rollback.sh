#!/usr/bin/env bash
# Revierte el drop-in SSH al estado previo a la última ejecución de 20_ssh.sh.
# Lo dispara un temporizador de systemd si no se confirma el cambio a tiempo
# (`20_ssh.sh --confirm`). Se instala en /usr/local/sbin/autoops-ssh-rollback.
set -euo pipefail

CONF=/etc/ssh/sshd_config.d/10-autoops.conf
STATE_DIR=/var/lib/autoops-provision/ssh

if [[ -f $STATE_DIR/10-autoops.conf.prev ]]; then
  cp -p "$STATE_DIR/10-autoops.conf.prev" "$CONF"
elif [[ -f $STATE_DIR/10-autoops.conf.absent ]]; then
  rm -f "$CONF"
else
  echo "autoops-ssh-rollback: sin estado previo guardado." >&2
  exit 1
fi

/usr/sbin/sshd -t
if systemctl is-active --quiet ssh; then
  systemctl reload ssh
fi
logger -t autoops-ssh-rollback "configuración SSH revertida al estado previo"
echo "autoops-ssh-rollback: configuración SSH revertida."
