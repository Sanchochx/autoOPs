# US-PROV-001: Bootstrap Idempotente y Verificación del Host

**Épica:** 12 — Provisioning
**Prioridad:** ALTA
**Estimación:** 8 pts
**Dependencias:** US-HOST-001, US-HOST-002, US-HOST-003, US-NET-001, US-NET-002, US-SYS-001, US-SYS-002, US-SYS-003, US-SYS-004
**Estado:** Pendiente

---

## Historia de Usuario

**Como** ingeniero DevOps,
**necesito** un único punto de entrada que aprovisione un Ubuntu Server limpio y otro que verifique todos los controles de seguridad,
**para** reproducir el servidor de forma idéntica en la VM de VirtualBox y en AWS EC2 y detectar cualquier desviación.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Orquestador `bootstrap.sh`**
  - `scripts/provision/bootstrap.sh` ejecuta en orden los scripts numerados (`10_users` → `70_systemd`, `80_backup`), con `set -euo pipefail`, validación previa de variables obligatorias (falla con mensaje claro si falta alguna), comprobación de ejecución como root/sudo y de que el SO es Ubuntu 24.04.
  - Orden crítico: SSH con llave y UFW (permitiendo SSH) antes de cerrar accesos; `45_docker_ufw` después de Docker.
  - **Verificación:** ejecución completa sobre la VM limpia sin errores.

- [ ] **CA-2: Idempotencia y Variables Documentadas**
  - Plantilla `scripts/provision/provision.env.example` con todas las variables (admin, llaves, CIDR, puertos, backups) y descripción; ningún secreto en el repositorio.
  - **Verificación:** una segunda ejecución del bootstrap no produce cambios (salida "sin cambios") ni errores.

- [ ] **CA-3: `verify.sh` Unificado**
  - `scripts/provision/verify.sh` ejecuta todos los `checks/*.sh`, imprime una tabla `OK`/`FAIL` por control y devuelve código distinto de 0 si algo falla.
  - **Verificación:** pasa en la VM aprovisionada y falla al alterar a mano un control (p. ej. `PasswordAuthentication yes` o `ufw disable`).

- [ ] **CA-4: Validación en VM Limpia y Documentación**
  - Ciclo completo documentado en `infra/README.md`: snapshot de la VM limpia de Ubuntu 24.04 → bootstrap → `verify.sh` → reinicio → stack `healthy` → flujo end-to-end desde el navegador.
  - Actualizar `CLAUDE.md` (estructura del monorepo: `scripts/`, `infra/`) y `README.md`.
  - **Verificación:** la prueba completa se ejecuta desde cero en una VM nueva y todos los checks pasan tras el reinicio.

---

## Notas Técnicas

- **Sin Ansible:** decisión del proyecto; Bash idempotente y verificación explícita.
- **Entorno de prueba:** VirtualBox con Ubuntu Server 24.04 LTS; EC2 es solo el destino final y no se valida en esta fase.
- **Fuera de alcance:** Terraform/aprovisionamiento de la instancia, TLS y reverse proxy y CI/CD (Fase 5), auditd/Lynis (excluidos).
