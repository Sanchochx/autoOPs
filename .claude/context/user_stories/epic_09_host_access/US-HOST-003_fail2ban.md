# US-HOST-003: Protección contra Fuerza Bruta (fail2ban)

**Épica:** 09 — Host Access & Identity
**Prioridad:** ALTA
**Estimación:** 3 pts
**Dependencias:** US-HOST-002
**Estado:** Completada

---

## Historia de Usuario

**Como** administrador del servidor,
**necesito** bloquear automáticamente las IP que intentan adivinar credenciales SSH,
**para** reducir el ruido y el riesgo de ataques persistentes contra el puerto expuesto.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Instalación y Jail de sshd**
  - Script idempotente `scripts/provision/30_fail2ban.sh` que instala `fail2ban` y despliega `jail.d/autoops.local` (plantilla en `infra/fail2ban/`) con el jail `sshd` activo, `backend = systemd` (lee journald, sin archivos de log) y el puerto tomado de la variable de SSH.
  - **Verificación:** `fail2ban-client status sshd` muestra el jail activo.

- [x] **CA-2: Política de Ban y Lista Blanca**
  - Parámetros por variable de entorno: `maxretry`, `findtime`, `bantime` (con incremento progresivo) y `ignoreip` para la IP/CIDR del admin y la red local de la VM.
  - **Verificación:** 3-5 intentos fallidos desde una IP no incluida en `ignoreip` generan un ban; la IP de `ignoreip` nunca se bloquea.

- [x] **CA-3: Acción de Ban Compatible con Firewall y Verificación**
  - Dejar la acción de baneo lista para UFW (`banaction = ufw`) o documentar la compatibilidad con US-NET-001, para que ambas piezas no se pisen.
  - Check `scripts/provision/checks/30_fail2ban.sh` (servicio activo, jail cargado, `ignoreip` presente).
  - **Verificación:** el check pasa; `fail2ban-client set sshd unbanip <ip>` revierte un ban.

---

## Notas Técnicas

- **Logging cloud-native:** fail2ban lee de journald; no se configuran archivos de log propios.
- **Fuera de alcance:** jails para Traefik/Nginx (Fase 5), notificaciones por correo.
