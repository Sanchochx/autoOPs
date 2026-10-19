# US-NET-001: Firewall UFW con Política Deny-by-Default

**Épica:** 10 — Network Security
**Prioridad:** CRÍTICA
**Estimación:** 5 pts
**Dependencias:** US-HOST-002
**Estado:** Completada

---

## Historia de Usuario

**Como** administrador del servidor,
**necesito** un firewall de host que niegue todo el tráfico entrante salvo lo explícitamente autorizado,
**para** exponer únicamente SSH y los puertos web previstos y que cualquier otro servicio quede inaccesible desde la red.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Política por Defecto y Acceso SSH Seguro**
  - Script idempotente `scripts/provision/40_ufw.sh`: `default deny incoming`, `default allow outgoing`, `default deny routed`.
  - Permitir SSH con `ufw limit` (rate limiting) en el puerto leído de la misma variable usada en US-HOST-002, **antes** de habilitar el firewall.
  - **Verificación:** con UFW activo, la sesión SSH existente se mantiene y una nueva conexión funciona; el resto de puertos entrantes está cerrado.

- [x] **CA-2: Puertos Web Preparados para la Fase 5** _(apertura de 80/443 diferida a la Fase 5: hoy es opt-in con `UFW_WEB_PORTS`; `ADMIN_CIDR` implementado)_
  - Permitir `80/tcp` y `443/tcp` (puertos configurables por variable) para el futuro reverse proxy; documentar que el resto de puertos publicados por Docker no se abren aquí.
  - Opción para restringir el origen de SSH a un CIDR (`ADMIN_CIDR`) cuando se defina.
  - **Verificación:** `ufw status verbose` muestra únicamente las reglas esperadas.

- [x] **CA-3: Logging y Verificación**
  - `ufw logging low` (los registros van a journald/kernel, sin archivos propios de la aplicación).
  - Check `scripts/provision/checks/40_ufw.sh`: UFW activo, política por defecto y reglas exactas esperadas.
  - **Verificación:** el check pasa; añadir una regla ajena lo hace fallar.

---

## Notas Técnicas

- **Limitación conocida:** UFW **no** filtra los puertos publicados por Docker (`PORT` del Gateway y `FRONTEND_PORT` siguen alcanzables desde fuera). Se resuelve en US-NET-002; hasta entonces no se considera cerrada la exposición.
- **Riesgo de bloqueo:** habilitar UFW siempre después de permitir SSH; mantener la consola de VirtualBox como recuperación.
- **Fuera de alcance:** IPv6 avanzado, reglas de salida restrictivas (egress filtering), WAF.
