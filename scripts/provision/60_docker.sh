#!/usr/bin/env bash
# US-SYS-002: Docker Engine + Compose desde el repositorio oficial y daemon.json endurecido. Idempotente.
#
#   sudo ./scripts/provision/60_docker.sh
#
# Variables (todas opcionales):
#   DOCKER_VERSION               versión apt de docker-ce y docker-ce-cli (ej. 5:27.3.1-1~ubuntu.24.04~noble);
#                                vacío = la última del repositorio
#   DOCKER_CONTAINERD_VERSION    ídem para containerd.io
#   DOCKER_COMPOSE_VERSION       ídem para docker-compose-plugin
#   DOCKER_BUILDX_VERSION        ídem para docker-buildx-plugin
#   DOCKER_APT_SUITE             suite del repositorio (por defecto VERSION_CODENAME de /etc/os-release)
#   DOCKER_GPG_FINGERPRINT       huella esperada de la llave de Docker (por defecto, la oficial)
#   SERVICE_USER=autoops         único usuario que pertenece al grupo docker
# Ver infra/docker/README.md. El firewall (Docker ↔ UFW) se resuelve en US-NET-002.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DAEMON_SRC="${REPO_ROOT}/infra/docker/daemon.json"
DAEMON_DST=/etc/docker/daemon.json
KEYRING=/etc/apt/keyrings/docker.asc
SOURCES=/etc/apt/sources.list.d/docker.sources
DOCKER_URL=https://download.docker.com/linux/ubuntu

require_root
SERVICE_USER="${SERVICE_USER:-autoops}"
DOCKER_GPG_FINGERPRINT="${DOCKER_GPG_FINGERPRINT:-9DC858229FC7DD38854AE2D88D81803C0EBFCD88}"
DOCKER_GPG_FINGERPRINT="${DOCKER_GPG_FINGERPRINT// /}"
DOCKER_APT_SUITE="${DOCKER_APT_SUITE:-$(. /etc/os-release && echo "${VERSION_CODENAME:-}")}"
declare -A PIN=(
  [docker-ce]="${DOCKER_VERSION:-}" [docker-ce-cli]="${DOCKER_VERSION:-}"
  [containerd.io]="${DOCKER_CONTAINERD_VERSION:-}"
  [docker-compose-plugin]="${DOCKER_COMPOSE_VERSION:-}" [docker-buildx-plugin]="${DOCKER_BUILDX_VERSION:-}"
)
PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)

[[ -n $DOCKER_APT_SUITE ]] || die "No se pudo determinar la suite; define DOCKER_APT_SUITE."
[[ $DOCKER_GPG_FINGERPRINT =~ ^[0-9A-Fa-f]{40}$ ]] || die "DOCKER_GPG_FINGERPRINT inválida (40 hex)."
[[ $(. /etc/os-release && echo "$ID") == ubuntu ]] || die "Este script soporta Ubuntu (repositorio ${DOCKER_URL})."
id "$SERVICE_USER" >/dev/null 2>&1 || die "El usuario ${SERVICE_USER} no existe (ejecuta antes 10_users.sh)."
jq empty "$DAEMON_SRC" || die "${DAEMON_SRC} no es JSON válido."
if jq -e 'has("hosts") or (.iptables == false)' "$DAEMON_SRC" >/dev/null; then
  die "daemon.json no debe definir 'hosts' (sin exposición TCP) ni desactivar iptables."
fi
has_systemd() { [[ -d /run/systemd/system ]]; }
export DEBIAN_FRONTEND=noninteractive

# Paquetes que chocan con docker-ce: no se eliminan solos (podrían tener contenedores/datos).
for conflict in docker.io docker-doc docker-compose podman-docker; do
  ! dpkg -s "$conflict" >/dev/null 2>&1 || die "Está instalado '${conflict}', que choca con docker-ce. Retíralo manualmente (sudo apt-get remove ${conflict}) y reintenta."
done

# --- CA-1: repositorio oficial con llave verificada ----------------------------------
install -d -m 755 /etc/apt/keyrings
key_fpr() { gpg --show-keys --with-colons "$1" 2>/dev/null | awk -F: '$1 == "fpr" { print $10; exit }'; }
if [[ ! -f $KEYRING ]] || [[ "$(key_fpr "$KEYRING")" != "${DOCKER_GPG_FINGERPRINT^^}" ]]; then
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  curl -fsSL "${DOCKER_URL}/gpg" -o "$tmp"
  [[ "$(key_fpr "$tmp")" == "${DOCKER_GPG_FINGERPRINT^^}" ]] \
    || die "La huella de la llave descargada no coincide con DOCKER_GPG_FINGERPRINT: no se instala."
  install -m 644 -o root -g root "$tmp" "$KEYRING"
  log_change "instalada y verificada la llave GPG de Docker en ${KEYRING}"
fi

arch="$(dpkg --print-architecture)"
ensure_file "$SOURCES" "Types: deb
URIs: ${DOCKER_URL}
Suites: ${DOCKER_APT_SUITE}
Components: stable
Architectures: ${arch}
Signed-By: ${KEYRING}"
chmod 644 "$SOURCES"
policy="$(apt-cache policy docker-ce 2>/dev/null || true)"
if ((FILE_CHANGED)) || [[ $policy != *download.docker.com* ]]; then
  apt-get update -qq || { rm -f "$SOURCES"; die "apt update falló con la suite '${DOCKER_APT_SUITE}'; ¿existe en ${DOCKER_URL}/dists/? (usa DOCKER_APT_SUITE)."; }
fi

docker_preinstalled=0
dpkg -s docker-ce >/dev/null 2>&1 && docker_preinstalled=1

# --- CA-2: daemon.json ANTES de instalar (el primer arranque ya sale endurecido) -------
install -d -m 755 /etc/docker
DAEMON_CHANGED=0
if [[ ! -f $DAEMON_DST ]] || ! cmp -s "$DAEMON_SRC" "$DAEMON_DST"; then
  [[ -f $DAEMON_DST ]] && cp -p "$DAEMON_DST" "${DAEMON_DST}.autoops-prev"
  install -m 644 -o root -g root "$DAEMON_SRC" "$DAEMON_DST"
  DAEMON_CHANGED=1
  log_change "escrito ${DAEMON_DST}"
fi

# --- CA-1: instalación (solo lo que falta o difiere de la versión fijada) ----------------
to_install=()
for pkg in "${PACKAGES[@]}"; do
  want="${PIN[$pkg]}"
  have="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
  if [[ -z $have ]]; then
    to_install+=("${pkg}${want:+=$want}")
  elif [[ -n $want && $have != "$want" ]]; then
    to_install+=("${pkg}=${want}")
  fi
done
if ((${#to_install[@]} > 0)); then
  apt-get install -y -qq --allow-downgrades "${to_install[@]}"
  log_change "instalados: ${to_install[*]}"
fi

# --- CA-2: validar y, si el demonio ya corría con otra config, reiniciarlo -----------------
if ((DAEMON_CHANGED)); then
  if ! dockerd --validate --config-file="$DAEMON_DST" >/dev/null 2>&1; then
    dockerd --validate --config-file="$DAEMON_DST" >&2 || true
    if [[ -f ${DAEMON_DST}.autoops-prev ]]; then mv -f "${DAEMON_DST}.autoops-prev" "$DAEMON_DST"; else rm -f "$DAEMON_DST"; fi
    die "daemon.json no valida con 'dockerd --validate'; se restauró el anterior."
  fi
  rm -f "${DAEMON_DST}.autoops-prev"
fi
if has_systemd; then
  systemctl enable docker containerd >/dev/null 2>&1
  if ! systemctl is-active --quiet docker; then
    systemctl start docker
    log_change "docker iniciado"
  elif ((DAEMON_CHANGED && docker_preinstalled)); then
    systemctl restart docker
    log_change "docker reiniciado con el nuevo daemon.json (los contenedores sin restart policy se detienen)"
  fi
fi

# --- CA-3: acceso al socket (grupo docker = root) -----------------------------------------------
getent group docker >/dev/null || groupadd --system docker
in_group "$SERVICE_USER" docker || { usermod -aG docker "$SERVICE_USER"; log_change "${SERVICE_USER} añadido al grupo docker"; }
for member in $(getent group docker | cut -d: -f4 | tr ',' ' '); do
  if [[ $member != "$SERVICE_USER" ]]; then
    gpasswd --delete "$member" docker >/dev/null
    log_change "${member} retirado del grupo docker (usa sudo docker)"
  fi
done

docker version --format 'Docker Engine {{.Server.Version}}'
docker compose version
log_info "60_docker.sh finalizado."
