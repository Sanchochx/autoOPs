# Resumen de Fase 3: Contenerización Avanzada

**Proyecto:** AutoOps — Plataforma SRE Multi-Agente Autohospedada
**Fecha de cierre:** 2026-10-18
**Estado:** Completada (4/4 US)

| US | Épica | Commit |
|----|-------|--------|
| US-DOCK-001 Builds multi-stage para API Gateway y AI Engine | 08 | `359ec92` |
| US-DOCK-002 Dockerfile multi-stage del Frontend (Vite + Nginx) | 08 | `41c855e` |
| US-DOCK-003 Dockerfiles de los servidores MCP (transporte SSE) | 08 | `efc7f62` |
| US-DOCK-004 Orquestación global con Docker Compose | 08 | `35e3889` |

---

## 📝 Changes Made

- **Imágenes:** multi-stage, versiones fijadas y usuario non-root en `api-gateway`, `frontend` (Nginx sin privilegios, puerto 8080) y `mcp-logs`.
- **Servidor MCP:** refactorizado de stdio a transporte **SSE** para poder vivir en su propio contenedor; el Gateway lo consume en `http://mcp-logs:<MCP_LOGS_PORT>/sse`.
- **AI Engine:** sigue ejecutándose en proceso dentro de la imagen del Gateway (decisión A de US-DOCK-001); no es servicio de Compose.
- **Orquestación:** `docker-compose.yml` levanta `postgres`, `mcp-logs`, `api-gateway` y `frontend` con un único `docker compose up -d --build`. Toda la configuración sale de `.env` con `${VAR:?mensaje}` para las obligatorias.
- **Migraciones:** servicio efímero `migrate` bajo el profile `tools` (`docker compose --profile tools run --rm migrate`); el Gateway nunca migra al arrancar.
- **Salud y arranque:** `healthcheck` por servicio y `depends_on: service_healthy` (Gateway espera a Postgres y MCP; Frontend espera al Gateway). `restart: unless-stopped`; logs al driver por defecto (stdout/stderr).

## 🌐 Topología de Redes

| Red | `internal` | Miembros | Propósito |
|-----|-----------|----------|-----------|
| `frontend_net` | no | `frontend`, `api-gateway` | Publicación al host y salida a Internet (el Gateway llama al proveedor de IA) |
| `backend_net` | **sí** | `api-gateway`, `postgres`, `migrate` | Acceso a datos; sin Internet ni host |
| `mcp_net` | **sí** | `api-gateway`, `mcp-logs` | Herramientas MCP; sin Internet ni host |

- Solo `frontend` (`FRONTEND_PORT`) y `api-gateway` (`PORT`) publican puertos. **Hoy lo hacen en todas las interfaces (`0.0.0.0`)**.
- `postgres` **no publica puertos** en el compose base. El binding a loopback se obtiene opcionalmente con `docker-compose.dev-db.yml`, que lo une a `db_host_net` (las redes `internal` no admiten `ports:`). Solo para desarrollo.
- `mcp-logs` solo es alcanzable desde el Gateway; no ve Postgres ni Internet.

## 📂 Files Modified/Created

| Ruta | Propósito |
|------|-----------|
| `docker-compose.yml` | Orquestación completa, redes, healthchecks, hardening (`cap_drop: ALL`, `no-new-privileges`, `read_only`, `tmpfs`) |
| `docker-compose.dev-db.yml` | Override opcional para exponer Postgres en loopback (desarrollo) |
| `apps/api_gateway/Dockerfile`, `apps/frontend/Dockerfile` (+ `nginx.conf`), `services/mcp-servers/logs_server/Dockerfile` | Imágenes multi-stage non-root |
| `.env.example` | Puertos publicados, `DATABASE_URL`, `CORS_ALLOWED_ORIGINS`, `VITE_*` (build-args), `AI_MODEL_NAME`, etc. |

## 🎯 Rationale

- **Aislamiento por capas:** las dos redes `internal` hacen que un contenedor comprometido (p. ej. el MCP) no pueda exfiltrar por red ni llegar a la base de datos; solo el Gateway une los tres mundos.
- **Hardening por defecto:** `cap_drop: ALL` con excepciones mínimas (Postgres necesita `CHOWN/DAC_OVERRIDE/FOWNER/SETGID/SETUID`), filesystem de solo lectura y `no-new-privileges`.
- **Migraciones explícitas:** evita carreras entre réplicas y mantiene el arranque del Gateway sin efectos laterales sobre el esquema.
- **Twelve-Factor:** sin credenciales, URLs ni puertos hardcodeados; las `VITE_*` son build-time y deben ser alcanzables desde el navegador.
- **Validación:** stack completo probado en local (healthchecks en verde, streaming por WebSocket y conexión MCP por SSE de extremo a extremo).

## 🚀 Next Steps

**Fase 4: Infraestructura Linux y Seguridad** (Ubuntu Server 24.04 LTS dedicado, validado en VM limpia de VirtualBox; EC2 es solo el destino final).

- **Decisiones tomadas:** provisioning con **scripts Bash idempotentes** + `verify.sh` (sin Ansible); **Docker Engine estándar** con `daemon.json` endurecido (sin rootless, para no complicar puertos bajos en la Fase 5); `auditd`/Lynis **fuera de alcance**.
- **Puntos de atención heredados de esta fase:**
  1. Docker publica `PORT` y `FRONTEND_PORT` saltándose UFW (cadena `DOCKER-USER`): se resuelve en US-NET-002.
  2. El stack debe arrancar solo tras un reinicio del host: US-SYS-003 (systemd).
  3. `.env` contiene secretos en claro: permisos `0600` y propietario `autoops` (US-HOST-001).
  4. Sin backups de `postgres_data`: US-SYS-004.
- **Fase 5 (después):** Traefik/Nginx + Let's Encrypt y GitHub Actions por SSH, apoyándose en la llave de despliegue restringida y el firewall de la Fase 4.
- **Deuda de producto sin fase asignada:** Agente Ejecutor/HITL, JWT y cliente MCP real en el investigador.
