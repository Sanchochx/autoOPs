#!/usr/bin/env bash
# Reglas UFW esperadas, compartidas por 40_ufw.sh y su check. Se carga con `source`.
# Formato = el de `ufw show added` (lista de reglas definidas, activo o no).
#
# expected_ufw_rules <ssh_port> <admin_cidr|""> <web_ports...>: una regla por línea.
expected_ufw_rules() {
  local ssh_port=$1 admin_cidr=$2 port
  shift 2
  if [[ -n $admin_cidr ]]; then
    echo "ufw limit from ${admin_cidr} to any port ${ssh_port} proto tcp"
  else
    echo "ufw limit ${ssh_port}/tcp"
  fi
  for port in "$@"; do echo "ufw allow ${port}/tcp"; done
}

# validate_ufw_inputs: valida ADMIN_CIDR y UFW_WEB_PORTS (variables ya cargadas).
validate_ufw_inputs() {
  local port
  if [[ -n ${ADMIN_CIDR:-} ]]; then
    python3 -I -c 'import ipaddress,sys; ipaddress.ip_network(sys.argv[1], strict=False)' "$ADMIN_CIDR" 2>/dev/null \
      || die "ADMIN_CIDR inválido: '${ADMIN_CIDR}' (usa una IP o CIDR)."
  fi
  for port in ${UFW_WEB_PORTS:-}; do
    [[ $port =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)) || die "Puerto web inválido en UFW_WEB_PORTS: '${port}'."
  done
}

# added_ufw_rules: reglas definidas, normalizadas al formato de expected_ufw_rules.
# `ufw show added` agrega el sufijo ` comment '...'` y una línea de encabezado: se descartan.
added_ufw_rules() {
  local added
  added="$(ufw show added)"
  sed -nE "/^ufw /{s/ comment '[^']*'\$//;p}" <<<"$added"
}
