# Docker Engine en el host

Gestionado por `scripts/provision/60_docker.sh` (verificación: `scripts/provision/checks/60_docker.sh`).

| Archivo | Destino en el host |
|---|---|
| `daemon.json` | `/etc/docker/daemon.json` |

El script también crea `/etc/apt/keyrings/docker.asc` y `/etc/apt/sources.list.d/docker.sources` (repositorio oficial, `Signed-By`).

## Variables (todas opcionales)

| Variable | Descripción |
|---|---|
| `DOCKER_VERSION` | Versión apt de `docker-ce` y `docker-ce-cli`; vacío = la última del repositorio |
| `DOCKER_CONTAINERD_VERSION`, `DOCKER_COMPOSE_VERSION`, `DOCKER_BUILDX_VERSION` | Ídem para cada paquete |
| `DOCKER_APT_SUITE` | Suite del repositorio (por defecto, `VERSION_CODENAME`); útil si Docker aún no publica tu release |
| `DOCKER_GPG_FINGERPRINT` | Huella esperada de la llave (por defecto, la oficial de Docker) |
| `SERVICE_USER` | Único miembro del grupo `docker` (`autoops`) |

Versiones disponibles: `apt-cache madison docker-ce`. Sin fijar versión, `apt-get upgrade` (50_os_baseline.sh) puede actualizar Docker; con `live-restore` los contenedores sobreviven al reinicio del demonio.

## `daemon.json`

| Clave | Motivo |
|---|---|
| `no-new-privileges: true` | Los procesos de los contenedores no ganan privilegios vía setuid |
| `log-driver: json-file` + `max-size 10m` / `max-file 3` | Los contenedores siguen emitiendo a stdout/stderr; la rotación evita llenar el disco |
| `live-restore: true` | Reiniciar o actualizar el demonio no detiene los contenedores |
| `userland-proxy: false` | Los puertos publicados usan reglas iptables en vez del proxy `docker-proxy` |

**No** se define `"iptables": false` (rompería la salida a Internet de los contenedores y las redes `internal` del compose) ni `"hosts"` (el demonio no se expone por TCP). El filtrado de puertos publicados frente a UFW se resuelve en US-NET-002 con la cadena `DOCKER-USER`.

## Decisión: Docker estándar, no rootless

- El reverse proxy de la Fase 5 necesita enlazar los puertos 80/443 (<1024), lo que complica el modo rootless.
- Las redes `internal` y el modelo de red del compose se apoyan en iptables gestionado por el demonio, que rootless no ofrece igual.
- Mitigaciones adoptadas: `no-new-privileges`, grupo `docker` restringido, sin exposición TCP, contenedores non-root (Dockerfiles de la Fase 3).
- `userns-remap` queda como mejora futura (cambia propietarios de volúmenes y requiere probar el stack completo).

## Acceso

- Pertenecer al grupo `docker` equivale a ser `root`. Solo `autoops` (ejecutado por systemd, US-SYS-003) está en el grupo; el script retira al resto. El admin usa `sudo docker`.
- El socket `/var/run/docker.sock` mantiene `root:docker 660`.

## Verificar el stack (CA-4)

```bash
cd /opt/autoops    # o el directorio del repositorio
sudo docker compose up -d --build
sudo docker compose ps          # todos los servicios deben quedar healthy
```
