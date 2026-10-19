# US-HOST-001: Usuarios Nativos y Modelo de Privilegios

**Épica:** 09 — Host Access & Identity
**Prioridad:** CRÍTICA
**Estimación:** 5 pts
**Dependencias:** US-DOCK-004
**Estado:** Completada

---

## Historia de Usuario

**Como** administrador del servidor Ubuntu,
**necesito** separar la identidad humana de administración de la identidad de servicio que ejecuta AutoOps, con privilegios mínimos,
**para** que ni un acceso interactivo comprometido ni un proceso de la plataforma tengan más poder del necesario.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Usuario Administrador y Root Bloqueado**
  - Script idempotente `scripts/provision/10_users.sh` que crea un usuario admin nominal (nombre por variable de entorno, p. ej. `ADMIN_USER`) en el grupo `sudo`.
  - Bloquear la contraseña de `root` (`passwd -l root`); `sudo` requiere contraseña (sin `NOPASSWD` salvo lo estrictamente necesario y documentado).
  - **Verificación:** `su -` como root falla; el admin ejecuta `sudo -v`; reejecutar el script no produce cambios ni errores.

- [x] **CA-2: Usuario de Servicio `autoops`**
  - Crear usuario de sistema `autoops` (`--system`, sin contraseña, shell `/usr/sbin/nologin`, sin acceso SSH) con home/propiedad en `/opt/autoops`.
  - UID/GID fijos y documentados para que coincidan entre reinicios y re-aprovisionamientos.
  - **Verificación:** `su - autoops` y login por SSH fallan; `/opt/autoops` pertenece a `autoops:autoops` con modo `750`.

- [x] **CA-3: Permisos del Código y Secretos**
  - El repositorio se despliega en `/opt/autoops`; el archivo `.env` queda `autoops:autoops` con modo `0600`. Ningún secreto en archivos legibles por "otros".
  - `umask 027` por defecto para el usuario de servicio y política de contraseñas mínima (`pwquality`) para el admin.
  - **Verificación:** `stat` confirma los modos; un tercer usuario sin privilegios no puede leer `.env` ni `/opt/autoops`.

- [x] **CA-4: Política de Acceso a Docker y Verificación**
  - Decidir y documentar quién opera Docker: pertenecer al grupo `docker` equivale a `root`, por lo que **solo** el usuario `autoops` (ejecutado por systemd, US-SYS-003) y el admin vía `sudo` lo usarán; el admin no se añade al grupo `docker`.
  - Crear `scripts/provision/checks/10_users.sh` con las comprobaciones de CA-1..CA-3 (salida `OK`/`FAIL` por control y código de salida distinto de 0 si algo falla).
  - **Verificación:** el check pasa en la VM limpia tras ejecutar el script y falla si se altera cualquier control.

---

## Notas Técnicas

- **Entorno de prueba:** VM limpia de VirtualBox con Ubuntu Server 24.04 LTS.
- **Convención de scripts:** Bash con `set -euo pipefail`, idempotentes, numerados por orden de ejecución (`NN_nombre.sh`) en `scripts/provision/`; cada US aporta además su check en `scripts/provision/checks/`. Sin valores hardcodeados: parámetros por variables de entorno documentadas.
- **Fuera de alcance:** SSH (US-HOST-002), instalación de Docker (US-SYS-002), unidad systemd (US-SYS-003), gestión de secretos con vault.
- **Riesgo de bloqueo:** no cerrar la sesión del admin hasta verificar `sudo` con el nuevo usuario.
