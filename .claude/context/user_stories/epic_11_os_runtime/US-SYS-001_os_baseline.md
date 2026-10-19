# US-SYS-001: Baseline del SO y Parches Automáticos

**Épica:** 11 — OS Hardening & Runtime
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-HOST-001
**Estado:** Completada

---

## Historia de Usuario

**Como** administrador del servidor,
**necesito** un sistema base mínimo, sincronizado y que reciba parches de seguridad sin intervención,
**para** reducir la superficie de ataque y evitar vulnerabilidades conocidas sin mantenimiento manual.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Paquetes Mínimos y Servicios Innecesarios**
  - Script idempotente `scripts/provision/50_os_baseline.sh`: actualizar el índice y el sistema, instalar solo las herramientas necesarias y revisar los servicios en escucha (`ss -tulpn`) deshabilitando los no requeridos.
  - **Verificación:** la lista de puertos en escucha tras el script es solo SSH (más los de systemd internos esperados) y queda documentada.

- [x] **CA-2: Parches de Seguridad Automáticos**
  - `unattended-upgrades` configurado solo para el canal de seguridad, con política de reinicio documentada (por defecto sin reinicio automático; ventana opcional por variable).
  - **Verificación:** `unattended-upgrade --dry-run` funciona y el timer `apt-daily-upgrade` está activo.

- [x] **CA-3: Sincronización Horaria**
  - `chrony` instalado y activo (los logs y los tokens JWT dependen de la hora correcta); zona horaria UTC por variable.
  - **Verificación:** `chronyc tracking` muestra sincronización.

- [x] **CA-4: Parámetros de Kernel (`sysctl`) y Verificación**
  - Drop-in `/etc/sysctl.d/99-autoops.conf` (plantilla en `infra/sysctl/`): `tcp_syncookies`, `rp_filter`, rechazo de `source route` y redirects ICMP, `kernel.kptr_restrict`, `kernel.dmesg_restrict`, `fs.protected_hardlinks/symlinks`, etc. **Sin** deshabilitar `ip_forward` (Docker lo necesita).
  - Check `scripts/provision/checks/50_os_baseline.sh` con los valores esperados.
  - **Verificación:** `sysctl --system` aplica sin errores y el check pasa; el stack de Compose sigue operativo.

---

## Notas Técnicas

- **Fuera de alcance:** auditd, Lynis, AppArmor/seccomp a medida, cifrado de disco.
- **Idempotencia:** reejecutar el script no debe reinstalar paquetes ni duplicar configuraciones.
