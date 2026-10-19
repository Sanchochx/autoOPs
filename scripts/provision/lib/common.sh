#!/usr/bin/env bash
# Utilidades compartidas por los scripts de aprovisionamiento y sus checks.
# Se carga con `source`; no se ejecuta directamente.

log_info()   { printf '[INFO]   %s\n' "$*"; }
log_change() { printf '[CAMBIO] %s\n' "$*"; }
log_warn()   { printf '[AVISO]  %s\n' "$*" >&2; }
die()        { printf '[ERROR]  %s\n' "$*" >&2; exit 1; }

require_root() {
  [[ $EUID -eq 0 ]] || die "Ejecuta este script con sudo o como root."
}

require_var() {
  local name
  for name in "$@"; do
    [[ -n "${!name:-}" ]] || die "Falta la variable obligatoria ${name}."
  done
}

# in_group <usuario> <grupo>: éxito si el usuario pertenece al grupo.
# (sin pipes: con `pipefail`, `grep -q` puede provocar falsos negativos)
in_group() {
  local group
  for group in $(id -nG "$1" 2>/dev/null); do
    [[ $group == "$2" ]] && return 0
  done
  return 1
}

# passwd_status <usuario>: P (contraseña usable), L (bloqueada) o NP (sin contraseña).
passwd_status() {
  passwd -S "$1" | awk '{print $2}'
}

# ensure_perms <ruta> <propietario:grupo> <modo>: corrige solo si hay diferencia.
ensure_perms() {
  local path=$1 owner=$2 mode=$3
  if [[ "$(stat -c '%U:%G %a' "$path")" != "${owner} ${mode}" ]]; then
    chown "$owner" "$path"
    chmod "$mode" "$path"
    log_change "${path} -> ${owner} ${mode}"
  fi
}

# ensure_file <ruta> <contenido>: escribe el archivo solo si cambia y deja
# FILE_CHANGED=1 (o 0) para que el llamador decida si hay que recargar algo.
FILE_CHANGED=0
ensure_file() {
  local path=$1 content=$2
  FILE_CHANGED=0
  if [[ ! -f $path ]] || [[ "$(cat "$path")" != "$content" ]]; then
    printf '%s\n' "$content" >"$path"
    FILE_CHANGED=1
    log_change "escrito ${path}"
  fi
}

# --- Checks: cada `check` imprime OK/FAIL y acumula fallos ---------------------
CHECK_FAILS=0

check() {
  local description=$1
  shift
  if "$@" >/dev/null 2>&1; then
    printf '[ OK ]   %s\n' "$description"
  else
    printf '[FAIL]   %s\n' "$description"
    CHECK_FAILS=$((CHECK_FAILS + 1))
  fi
}

check_finish() {
  if ((CHECK_FAILS > 0)); then
    printf '\n%d control(es) fallaron.\n' "$CHECK_FAILS" >&2
    exit 1
  fi
  printf '\nTodos los controles pasaron.\n'
}
