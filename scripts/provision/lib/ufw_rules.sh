#!/usr/bin/env bash
# Expected UFW rules, shared by 40_ufw.sh and its check. Loaded with `source`.
# Format = that of `ufw show added` (list of defined rules, active or not).
#
# expected_ufw_rules <ssh_port> <admin_cidr|""> <web_ports...>: one rule per line.
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

# validate_ufw_inputs: validates ADMIN_CIDR and UFW_WEB_PORTS (variables already loaded).
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

# added_ufw_rules: defined rules, normalized to the format of expected_ufw_rules.
# `ufw show added` appends the suffix ` comment '...'` and a header line: both are discarded.
added_ufw_rules() {
  local added
  added="$(ufw show added)"
  sed -nE "/^ufw /{s/ comment '[^']*'\$//;p}" <<<"$added"
}
