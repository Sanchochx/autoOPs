# US-DOCK-003: Dockerfiles para los Servidores MCP

**Épica:** 08 — Containerization & Orchestration
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-DOCK-001 (convenciones de build y usuario no-root), US-MCP-003
**Estado:** Pendiente

---

## Historia de Usuario

**Como** ingeniero DevOps,
**necesito** empaquetar cada servidor MCP en su propia imagen mínima y endurecida,
**para** que el acceso a logs, métricas y herramientas de infraestructura quede aislado del resto de la plataforma y solo sea alcanzable por la red autorizada.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Transporte de Red del Servidor de Logs**
  - Resolver la decisión abierta (ver Notas Técnicas) y adaptar `services/mcp-servers/logs_server/server.py` para que sea alcanzable por red dentro de un contenedor, leyendo host y puerto exclusivamente del entorno.
  - Conservar las herramientas existentes (`get_system_logs`, `get_db_metrics`) y los logs a stderr/stdout.
  - **Verificación:** el servidor arranca localmente con el nuevo transporte y un cliente MCP lista y ejecuta sus herramientas.

- [ ] **CA-2: Imagen del Servidor de Logs**
  - Crear `services/mcp-servers/logs_server/Dockerfile` multi-stage (`builder` + `runtime` sobre `python:3.11-slim` fijado) que instala solo `services/mcp-servers/logs_server/requirements.txt`, con capas de dependencias antes del código.
  - Ejecutar con usuario no-root y sin secretos en las capas; este servidor no requiere credenciales de BD ni claves de IA.
  - **Verificación:** `docker build` sin errores; `docker run` levanta el servidor y un cliente MCP en el host ejecuta `get_system_logs`; `id -u` ≠ `0`.

- [ ] **CA-3: Endurecimiento y Aislamiento**
  - Documentar y dejar preparadas (para su aplicación en Compose) las restricciones de runtime del contenedor: sistema de archivos raíz de solo lectura, `cap_drop: [ALL]`, `no-new-privileges`, sin puertos publicados al host y sin acceso a la red del resto de servicios salvo la red MCP.
  - Dejar una plantilla/convención (estructura de carpetas y Dockerfile base) para añadir el futuro servidor MCP de BD (`MCP_DB_SERVER_URL`) sin duplicar lógica.
  - **Verificación:** la imagen arranca correctamente con `--read-only --cap-drop ALL --security-opt no-new-privileges`; tamaño final registrado en el resumen de la US.

---

## Notas Técnicas

- **Decisión abierta (cerrar antes de implementar CA-1):** hoy `logs_server` usa transporte **stdio** (`mcp.run(transport="stdio")`), pensado para ser lanzado como subproceso por el cliente. En contenedores separados no es alcanzable por red, y `.env.example` ya define `MCP_LOGS_SERVER_URL` (HTTP). Opciones:
  - **A) Transporte HTTP (streamable-http) en el servidor:** aislamiento real por red, coherente con `MCP_LOGS_SERVER_URL`. Requiere ajustar el servidor y comprobar cómo el cliente del AI Engine se conecta (hoy lo hace vía stdio).
  - **B) Mantener stdio:** el AI Engine lanzaría el servidor como subproceso dentro de la misma imagen; no hay aislamiento de runtime, contradice el objetivo de esta US.
  - Recomendación: A. Si el cliente del AI Engine necesita cambios para conectarse por HTTP, acotarlos al mínimo y documentarlos.
- **Servidor MCP de BD:** aún no existe (solo su variable `MCP_DB_SERVER_URL`); crearlo queda fuera de alcance. Esta US solo asegura que añadirlo sea trivial.
- **Fuera de alcance:** servicios en `docker-compose.yml` y redes (US-DOCK-004), nuevas herramientas MCP, autenticación entre cliente y servidor MCP (a evaluar en Fase 4).
- **Principio de aislamiento:** los servidores MCP son la única vía a la infraestructura; sus imágenes no incluyen LangGraph ni código del Gateway.
- **Logging:** stdout/stderr, sin archivos ni volúmenes de logs.
- **Convenciones:** etapas nombradas (`builder`, `runtime`); versiones de imagen base fijadas (sin `latest`); `pip --no-cache-dir`.
