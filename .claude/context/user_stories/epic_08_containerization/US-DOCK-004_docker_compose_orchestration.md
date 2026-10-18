# US-DOCK-004: Orquestación Global con Docker Compose

**Épica:** 08 — Containerization & Orchestration
**Prioridad:** ALTA
**Estimación:** 8 pts
**Dependencias:** US-DOCK-001, US-DOCK-002, US-DOCK-003
**Estado:** Completada

---

## Historia de Usuario

**Como** ingeniero DevOps,
**necesito** levantar toda la plataforma (PostgreSQL, API Gateway, servidores MCP y Frontend) con un único `docker compose up`,
**para** tener un entorno reproducible con redes aisladas, datos persistentes y un orden de arranque correcto, idéntico en una VM local y en AWS EC2.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Servicios y Configuración por Entorno**
  - Ampliar `docker-compose.yml` (hoy solo PostgreSQL) con los servicios `api-gateway`, `mcp-logs`, `frontend` y el existente `postgres`, usando los `build:` de las US-DOCK-001/002/003 (contexto en la raíz del monorepo).
  - Toda la configuración se inyecta vía `env_file`/`environment:` desde `.env`; sin credenciales ni puertos hardcodeados. Documentar en `.env.example` las variables nuevas (p. ej. puertos publicados, `DATABASE_URL` apuntando al servicio `postgres`).
  - **Verificación:** `docker compose config` valida sin errores ni variables sin definir.

- [x] **CA-2: Redes Puente Aisladas**
  - Definir redes `bridge` separadas por responsabilidad: red de frontend (publica solo lo necesario al host), red de backend (`api-gateway` ↔ `postgres`, `internal: true`) y red MCP (`api-gateway` ↔ servidores MCP, `internal: true`).
  - Solo `frontend` y `api-gateway` publican puertos al host; `postgres` conserva el binding a `127.0.0.1` y los servidores MCP no publican nada. Aplicar el endurecimiento definido en US-DOCK-003 (`read_only`, `cap_drop`, `no-new-privileges`).
  - **Verificación:** desde el contenedor del Gateway se alcanza `postgres` y `mcp-logs`; `mcp-logs` no alcanza `postgres` ni Internet; el host no accede a los servidores MCP.

- [x] **CA-3: Volúmenes Persistentes y Migraciones**
  - Mantener el volumen nombrado `postgres_data` y garantizar que los datos sobreviven a `docker compose down` (sin `-v`).
  - Añadir un paso explícito y reproducible para ejecutar las migraciones Alembic (servicio efímero `migrate` con `profiles` o `docker compose run --rm`), no ejecutado automáticamente al arrancar el Gateway.
  - **Verificación:** tras `down` y `up`, los tickets creados antes siguen existiendo; el comando de migración deja el esquema en `head`.

- [x] **CA-4: Orden de Arranque y Salud (`depends_on`)**
  - Definir `healthcheck` en `postgres`, `api-gateway` (`/health`) y servidores MCP, y usar `depends_on` con `condition: service_healthy` (Gateway espera a Postgres y MCP; Frontend espera al Gateway).
  - Configurar `restart: unless-stopped` y logs a stdout/stderr (driver por defecto, sin volúmenes de logs).
  - **Verificación:** `docker compose up -d --build` levanta todo en orden con todos los servicios `healthy`; el flujo completo (crear ticket → streaming de la IA por WebSocket en el dashboard) funciona de extremo a extremo.

---

## Notas Técnicas

- **Fuera de alcance:** Traefik/Nginx como reverse proxy con SSL y Let's Encrypt (Fase 5), CI/CD y despliegue por SSH (Fase 5), hardening del host Ubuntu (Fase 4), gestión de secretos con Docker secrets/vault.
- **AI Engine:** hoy se ejecuta en proceso dentro del Gateway (decisión A de US-DOCK-001); por eso no es un servicio de Compose y el Gateway necesita acceso a la red MCP. Si se aísla como servicio (decisión B), se actualizará esta US.
- **Frontend:** las `VITE_*` se fijan en build-time; el `build:` debe pasar `args` desde `.env` y la URL pública del Gateway debe ser alcanzable desde el navegador (no un nombre de servicio interno).
- **CORS:** `CORS_ALLOWED_ORIGINS` debe incluir el origen publicado del frontend.
- **Redes `internal: true`:** sin salida a Internet; el Gateway necesita salida para llamar al proveedor de IA, por lo que debe pertenecer también a una red con egress (la de frontend/publicación).
- **Convenciones:** nombres de servicio en `kebab-case`; versiones de imagen fijadas; un `healthcheck` por servicio.
