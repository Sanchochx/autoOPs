# US-SYS-003: Servicio systemd para el Stack AutoOps

**Épica:** 11 — OS Hardening & Runtime
**Prioridad:** ALTA
**Estimación:** 8 pts
**Dependencias:** US-HOST-001, US-SYS-002, US-NET-002
**Estado:** Pendiente

---

## Historia de Usuario

**Como** administrador del servidor,
**necesito** que la plataforma arranque, se detenga y se reinicie como un servicio nativo de systemd,
**para** que AutoOps se recupere sola tras un reinicio del host y se opere con las herramientas estándar de Linux.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Unidad `autoops.service`**
  - Unidad (plantilla en `infra/systemd/`, instalada por `scripts/provision/70_systemd.sh`): `Type=oneshot`, `RemainAfterExit=yes`, `User=autoops`, `WorkingDirectory=/opt/autoops`, `After=docker.service network-online.target`, `Requires=docker.service`.
  - `ExecStart=docker compose up -d`, `ExecStop=docker compose down` (sin `-v`: los datos persisten) y `ExecReload` opcional; `TimeoutStartSec` acorde a los healthchecks.
  - **Verificación:** `systemctl start/stop/restart autoops` funciona y el stack queda `healthy`.

- [ ] **CA-2: Configuración y Sandboxing de la Unidad**
  - `EnvironmentFile`/`.env` en `/opt/autoops` (modo `0600`), sin secretos en la unidad. Directivas de aislamiento compatibles con Docker: `NoNewPrivileges=yes`, `ProtectHome=yes`, `PrivateTmp=yes`, `ProtectSystem=full` y `ReadWritePaths` acotados. Revisar con `systemd-analyze security autoops`.
  - **Verificación:** la unidad arranca con el sandboxing activo y la puntuación de `systemd-analyze security` queda documentada.

- [ ] **CA-3: Migraciones como Oneshot Manual**
  - `autoops-migrate.service` (`Type=oneshot`, sin `[Install]`, nunca activado en el arranque) que ejecuta `docker compose --profile tools run --rm migrate`, invocable con `systemctl start autoops-migrate`.
  - **Verificación:** el comando deja el esquema Alembic en `head`; `autoops.service` no lo ejecuta.

- [ ] **CA-4: Arranque en Boot y Resiliencia**
  - `systemctl enable autoops` y comprobación de la política de reinicio (`restart: unless-stopped` de Compose más `live-restore`).
  - Check `scripts/provision/checks/70_systemd.sh` (unidad habilitada, activa y servicios `healthy`).
  - **Verificación:** tras `sudo reboot` de la VM, el stack vuelve `healthy` sin intervención y los tickets previos siguen existiendo.

---

## Notas Técnicas

- **Logs:** `journalctl -u autoops` para el ciclo de vida; los logs de aplicación siguen en `docker compose logs` (stdout/stderr).
- **Usuario `autoops`:** necesita acceso al socket de Docker (grupo `docker`), único caso permitido por US-HOST-001.
- **Fuera de alcance:** health-watchdog avanzado, notificaciones de fallo, despliegue desde CI/CD (Fase 5).
