# US-SYS-002: Docker Engine en el Host y `daemon.json` Endurecido

**Épica:** 11 — OS Hardening & Runtime
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-SYS-001
**Estado:** Pendiente

---

## Historia de Usuario

**Como** administrador del servidor,
**necesito** instalar Docker Engine desde el repositorio oficial con una configuración de demonio segura por defecto,
**para** ejecutar el stack de AutoOps con rotación de logs, límites razonables y sin escaladas de privilegios.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Instalación desde el Repositorio Oficial**
  - Script idempotente `scripts/provision/60_docker.sh`: repositorio apt oficial de Docker con su llave GPG verificada, instalación de `docker-ce`, `docker-ce-cli`, `containerd.io` y los plugins `buildx` y `compose`; versiones fijables por variable.
  - **Verificación:** `docker version` y `docker compose version` funcionan; reejecutar el script no cambia nada.

- [ ] **CA-2: `daemon.json` Endurecido**
  - Plantilla `infra/docker/daemon.json`: `"no-new-privileges": true`, `"log-driver": "json-file"` con `max-size`/`max-file`, `"live-restore": true`, `"userland-proxy": false`. Sin desactivar `iptables`.
  - **Verificación:** `docker info` refleja la configuración; el stack de Compose arranca y sus contenedores respetan `no-new-privileges`.

- [ ] **CA-3: Acceso al Socket y Pertenencia a Grupos**
  - Sin usuarios en el grupo `docker` salvo `autoops` (ver US-HOST-001 CA-4); socket `/var/run/docker.sock` con permisos por defecto y sin exposición TCP del demonio.
  - **Verificación:** `ss -tlnp` no muestra el puerto 2375/2376; el admin usa `sudo docker`.

- [ ] **CA-4: Decisión Documentada y Verificación**
  - Registrar en `infra/docker/README.md` por qué se usa Docker estándar y no *rootless* (puertos <1024 del proxy de la Fase 5 y redes `internal`), y que `userns-remap` queda como mejora futura.
  - Check `scripts/provision/checks/60_docker.sh`.
  - **Verificación:** el check pasa y `docker compose up -d --build` deja todos los servicios `healthy`.

---

## Notas Técnicas

- **Logging cloud-native:** los contenedores siguen emitiendo a stdout/stderr; la rotación del driver evita que los logs llenen el disco.
- **Fuera de alcance:** Docker rootless, registro privado de imágenes, escaneo de imágenes.
