# US-DOCK-001: Builds Multi-Stage para API Gateway y AI Engine

**Épica:** 08 — Containerization & Orchestration
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-INT-002
**Estado:** Completada

---

## Historia de Usuario

**Como** ingeniero DevOps,
**necesito** empaquetar el API Gateway y el AI Engine en imágenes Docker independientes, eficientes y reproducibles mediante builds multi-stage,
**para** desplegarlos de forma aislada en cualquier host (VM local o AWS EC2) sin depender del entorno de desarrollo.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Imagen del API Gateway**
  - Crear `apps/api_gateway/Dockerfile` multi-stage: una etapa `builder` que instala dependencias (`requirements.txt`) y una etapa `runtime` mínima (`python:3.11-slim`) que solo copia lo necesario.
  - El contenedor escucha en `0.0.0.0` (`HOST`), toma `PORT` y el resto de la configuración exclusivamente del entorno, y emite logs a stdout/stderr.
  - **Verificación:** `docker build` termina sin errores; `docker run` con variables de entorno inyectadas levanta el Gateway y `GET /health` (o el endpoint de salud existente) responde `200`.

- [x] **CA-2: Imagen del AI Engine**
  - Crear `services/ai-engine/Dockerfile` multi-stage con las dependencias de `services/ai-engine/requirements.txt` únicamente, sin dependencias del Gateway.
  - Definir y documentar cómo se ejecuta el motor en contenedor (ver decisión abierta en Notas Técnicas).
  - **Verificación:** `docker build` termina sin errores; dentro del contenedor `ai_engine.graph` se importa y `build_graph` compila con un modelo simulado, sin red ni claves reales.

- [x] **CA-3: Eficiencia y Seguridad de las Imágenes**
  - Añadir `.dockerignore` (excluye `venv/`, `.env`, `.git/`, `tests/`, `__pycache__/`, `node_modules/`).
  - Ejecutar ambos procesos con un usuario no-root y sin secretos incrustados en capas.
  - **Verificación:** `docker history`/`docker run env` no muestran credenciales; `docker run --rm <imagen> id -u` devuelve un UID distinto de `0`; el tamaño final de cada imagen queda registrado en el resumen de la US.

---

## Notas Técnicas

- **Fuera de alcance:** `docker-compose.yml` completo con todos los servicios y redes aisladas, Dockerfile del frontend, servidores MCP, reverse proxy (Traefik/Nginx), CI/CD y publicación en registry. Se cubrirán en US posteriores de la Épica 08 y la Fase 5.
- **Decisión abierta (cerrar antes de implementar CA-2):** hoy el AI Engine **no es un servicio**: es una librería que el Gateway importa en proceso (`ai_engine.graph.compiled_graph`, vía `PYTHONPATH=.:services/ai-engine`). Opciones:
  - **A) Imagen del Gateway incluye `ai_engine`:** una sola imagen ejecutable; la imagen del AI Engine existe como artefacto de build/verificación y base de dependencias. No requiere cambios de código, pero no hay aislamiento de runtime.
  - **B) AI Engine como servicio independiente:** requiere un entrypoint (p. ej. API HTTP interna) y que el Gateway lo consuma por red en lugar de importar el módulo. Da aislamiento real, pero implica una US previa de refactor (cambia el contrato de US-INT-001/002).
  - Recomendación: A para esta US y abrir una US aparte para B si se requiere aislamiento de red.
- **`PYTHONPATH`:** debe fijarse con `ENV` en el Dockerfile (ver `.env.example`), no depender de un `.env` copiado a la imagen.
- **Variables de entorno:** todas inyectadas en runtime (`--env-file` o `environment:`); nunca `COPY .env`. Incluye `DATABASE_URL`, `AI_MODEL_NAME`, claves del proveedor y `WS_BROADCAST_TIMEOUT_SECONDS`.
- **Migraciones:** Alembic no se ejecuta al arrancar la imagen en esta US; queda como paso explícito (comando aparte) para una US de orquestación.
- **Docker/Compose:** `docker-compose.yml` solo define hoy PostgreSQL; no se modifica en esta US salvo que la decisión lo requiera.
- **Logging:** stdout/stderr, sin archivos locales ni volúmenes de logs.
- **Convenciones:** una sola responsabilidad por Dockerfile; etapas nombradas (`builder`, `runtime`); versiones de imagen base fijadas (sin `latest`).
