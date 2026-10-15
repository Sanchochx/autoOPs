# Resumen de Fase 1: Fundación y Core Multi-Agente

**Proyecto:** AutoOps — Plataforma SRE Multi-Agente Autohospedada
**Fecha de cierre:** 2026-10-15
**Estado:** Completada (5/5 US)

| US | Épica | Commit |
|----|-------|--------|
| US-MONO-001 Monorepo Setup | 01 | `6ed1169` |
| US-GATE-002 API Gateway base en FastAPI | 02 | `762b423` |
| US-MCP-003 Servidor MCP de logs y métricas simuladas | 03 | `47f555b` |
| US-LANG-004 Grafo base de agentes (Triaje e Investigación) | 04 | `1aa00ab` |
| US-FRONT-005 Dashboard admin e integración de WebSockets | 05 | `05b5284` |

---

## 📝 Changes Made

- **Monorepo:** estructura `apps/`, `services/`, `.claude/context/` y `.env.example` centralizado.
- **API Gateway (FastAPI):**
  - CORS configurable por entorno, restrictivo por defecto.
  - `GET /health` y `POST /api/v1/tickets` (validación Pydantic, UUID4 generado en servidor, sin persistencia).
  - Canal WebSocket `/ws/stream` con `ConnectionManager` (confirmación y eco).
  - Arranque local con `HOST`/`PORT` desde `.env`.
- **Servidor MCP (`logs_server`):** `FastMCP` por stdio con las tools `get_system_logs(service_name)` y `get_db_metrics()` sobre datos simulados.
- **Motor de IA (LangGraph):** grafo `START → triage_node → investigator_node → END`, con `AgentState`, nodos construidos por fábricas con dependencias inyectadas y `compiled_graph` de construcción diferida.
- **Frontend:** React 19 + Vite 8 + TypeScript strict + Tailwind v4. Store Zustand, cliente WebSocket con reconexión de espera creciente, layout con sidebar y `AgentConsole` accesible.

## 📂 Files Modified/Created

| Ruta | Propósito |
|------|-----------|
| `apps/api_gateway/main.py` | Fábrica `create_app()`, CORS y routers |
| `apps/api_gateway/config.py` | Lectura de `CORS_ALLOWED_ORIGINS` y `load_dotenv` propio (sin dependencias) |
| `apps/api_gateway/schemas.py` | `TicketCreate`, `TicketRead`, `TicketSeverity`, `HealthResponse` |
| `apps/api_gateway/routers/{health,tickets,ws}.py` | Endpoints REST y WebSocket |
| `apps/api_gateway/connection_manager.py` | Gestión de conexiones WebSocket (connect, disconnect, broadcast) |
| `apps/api_gateway/run.py` | Arranque: `python -m apps.api_gateway.run` |
| `services/mcp-servers/logs_server/server.py` | Servidor MCP por stdio, logs a stderr |
| `services/ai-engine/ai_engine/{state,nodes,graph,config}.py` | Estado, nodos, grafo y construcción del modelo desde el entorno |
| `apps/frontend/src/features/agent-console/` | Store, servicios, hooks y consola (estructura por feature) |
| `apps/frontend/src/layouts/` | `DashboardLayout` y `Sidebar` |
| `apps/frontend/vite.config.ts` | Tailwind v4, `envDir` en la raíz y puerto desde `VITE_DEV_SERVER_PORT` |
| `tests/` | 12 pruebas pytest (REST, WebSocket, grafo con modelo falso) |
| `.env.example`, `pytest.ini` | Variables nuevas (`HOST`, `CORS_ALLOWED_ORIGINS`, `AI_MODEL_NAME`, `VITE_DEV_SERVER_PORT`) y rutas de pytest |

## 🎯 Rationale

- **Qué se completó y por qué:** las tres capas de la arquitectura (Gateway, MCP/motor de IA, dashboard) existen y son ejecutables de forma independiente, con contratos mínimos entre ellas. Esto permite integrarlas en fases posteriores sin rehacer cimientos.
- **Cómo encaja:** el motor de IA nunca toca PostgreSQL ni el SO; la infraestructura se consulta solo vía MCP (hoy simulada). El frontend consume solo el Gateway.
- **Decisiones de diseño:**
  - **Twelve-Factor:** toda configuración viene de variables de entorno; ningún host, puerto u origen en el código.
  - **Logging cloud-native:** stdout/stderr; en el servidor MCP, stderr para no contaminar el canal JSON-RPC.
  - **`mcp<2`:** la v2 del SDK renombra `FastMCP` a `MCPServer`; se fijó la v1 y la migración queda como tarea futura.
  - **Paquete `ai_engine/`:** `services/ai-engine` tiene guion y no es importable; el subpaquete evita colisiones de nombres.
  - **Dependencias inyectadas en los nodos:** permiten probar el grafo con un modelo falso, sin red ni API key.
  - **`compiled_graph` diferido (`__getattr__`):** importar el módulo no exige credenciales.
  - **Tailwind v4:** plugin `@tailwindcss/vite`; `postcss` y `autoprefixer` no son necesarios.
  - **Consolidación de contexto:** un solo conjunto de US por épica (carpetas `epic_02_gateway`, `epic_03_mcp`, `epic_04_ai_engine`, `epic_05_frontend`) y prefijos `MONO`, `GATE`, `MCP`, `LANG`, `FRONT`.

### Alcance entregado frente al objetivo original
El objetivo de la fase describía el flujo completo ticket → triaje → investigación MCP → plan de remediación con aprobación HITL, visible en tiempo real. La Fase 1 entregó los bloques de ese flujo, pero **no el flujo integrado**:
- No hay Agente Ejecutor ni aprobación HITL.
- El motor de IA no está conectado al servidor MCP (solo un punto de inyección `context_provider`).
- El Gateway no invoca al grafo ni emite su razonamiento: `/ws/stream` es un eco.
- `POST /api/v1/tickets` no persiste (sin SQLAlchemy/Alembic/PostgreSQL) y no hay autenticación JWT.
- El frontend no lista tickets; solo muestra la consola.

## 🚀 Next Steps

1. **Integración end-to-end (siguiente prioridad):** cliente MCP real en el investigador, invocación del grafo desde el Gateway y emisión de eventos por `/ws/stream`.
2. **Agente Ejecutor y HITL:** plan de remediación con aprobación humana y su modal en el frontend.
3. **Persistencia y autenticación:** modelos SQLAlchemy, migraciones Alembic y JWT.
4. **Frontend:** tabla de tickets y login.
5. **Calidad base:** configuración y logging compartidos, y pipeline de CI (lint + tests).
6. **Fase 2 (contenerización):** Docker Compose, Traefik/Nginx con SSL y CI/CD por SSH. Considerar entonces `HOST=0.0.0.0` en contenedores y la migración a `mcp` v2.
7. **Deuda conocida:** verificación manual del flujo contra la API real de Anthropic, que no se ejecutó en esta fase.
