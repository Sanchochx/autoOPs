# Phase 1 Summary: Foundation and Multi-Agent Core

**Project:** AutoOps — Self-Hosted Multi-Agent SRE Platform
**Closing date:** 2026-10-15
**Status:** Completed (5/5 US)

| US | Epic | Commit |
|----|------|--------|
| US-MONO-001 Monorepo Setup | 01 | `6ed1169` |
| US-GATE-002 Base API Gateway in FastAPI | 02 | `762b423` |
| US-MCP-003 MCP server for simulated logs and metrics | 03 | `47f555b` |
| US-LANG-004 Base agent graph (Triage and Investigation) | 04 | `1aa00ab` |
| US-FRONT-005 Admin dashboard and WebSocket integration | 05 | `05b5284` |

---

## 📝 Changes Made

- **Monorepo:** `apps/`, `services/`, `.claude/context/` structure and a centralized `.env.example`.
- **API Gateway (FastAPI):**
  - CORS configurable per environment, restrictive by default.
  - `GET /health` and `POST /api/v1/tickets` (Pydantic validation, server-generated UUID4, no persistence).
  - WebSocket channel `/ws/stream` with `ConnectionManager` (acknowledgement and echo).
  - Local startup with `HOST`/`PORT` from `.env`.
- **MCP server (`logs_server`):** `FastMCP` over stdio with the tools `get_system_logs(service_name)` and `get_db_metrics()` over simulated data.
- **AI Engine (LangGraph):** graph `START → triage_node → investigator_node → END`, with `AgentState`, nodes built by factories with injected dependencies, and a lazily constructed `compiled_graph`.
- **Frontend:** React 19 + Vite 8 + TypeScript strict + Tailwind v4. Zustand store, WebSocket client with increasing-backoff reconnection, layout with sidebar and an accessible `AgentConsole`.

## 📂 Files Modified/Created

| Path | Purpose |
|------|---------|
| `apps/api_gateway/main.py` | `create_app()` factory, CORS and routers |
| `apps/api_gateway/config.py` | Reads `CORS_ALLOWED_ORIGINS` and its own `load_dotenv` (dependency-free) |
| `apps/api_gateway/schemas.py` | `TicketCreate`, `TicketRead`, `TicketSeverity`, `HealthResponse` |
| `apps/api_gateway/routers/{health,tickets,ws}.py` | REST and WebSocket endpoints |
| `apps/api_gateway/connection_manager.py` | WebSocket connection management (connect, disconnect, broadcast) |
| `apps/api_gateway/run.py` | Startup: `python -m apps.api_gateway.run` |
| `services/mcp-servers/logs_server/server.py` | MCP server over stdio, logs to stderr |
| `services/ai-engine/ai_engine/{state,nodes,graph,config}.py` | State, nodes, graph and model construction from the environment |
| `apps/frontend/src/features/agent-console/` | Store, services, hooks and console (feature-based structure) |
| `apps/frontend/src/layouts/` | `DashboardLayout` and `Sidebar` |
| `apps/frontend/vite.config.ts` | Tailwind v4, `envDir` at the root and port from `VITE_DEV_SERVER_PORT` |
| `tests/` | 12 pytest tests (REST, WebSocket, graph with a fake model) |
| `.env.example`, `pytest.ini` | New variables (`HOST`, `CORS_ALLOWED_ORIGINS`, `AI_MODEL_NAME`, `VITE_DEV_SERVER_PORT`) and pytest paths |

## 🎯 Rationale

- **What was completed and why:** the three layers of the architecture (Gateway, MCP/AI engine, dashboard) exist and can run independently, with minimal contracts between them. This allows integrating them in later phases without redoing the foundations.
- **How it fits:** the AI engine never touches PostgreSQL or the OS; infrastructure is queried only via MCP (simulated for now). The frontend consumes only the Gateway.
- **Design decisions:**
  - **Twelve-Factor:** all configuration comes from environment variables; no host, port or origin in the code.
  - **Cloud-native logging:** stdout/stderr; in the MCP server, stderr so as not to pollute the JSON-RPC channel.
  - **`mcp<2`:** v2 of the SDK renames `FastMCP` to `MCPServer`; v1 was pinned and the migration remains a future task.
  - **`ai_engine/` package:** `services/ai-engine` contains a hyphen and is not importable; the subpackage avoids name collisions.
  - **Dependencies injected into the nodes:** they allow testing the graph with a fake model, without network or API key.
  - **Deferred `compiled_graph` (`__getattr__`):** importing the module does not require credentials.
  - **Tailwind v4:** `@tailwindcss/vite` plugin; `postcss` and `autoprefixer` are not needed.
  - **Context consolidation:** a single set of US per epic (folders `epic_02_gateway`, `epic_03_mcp`, `epic_04_ai_engine`, `epic_05_frontend`) and prefixes `MONO`, `GATE`, `MCP`, `LANG`, `FRONT`.

### Delivered scope versus the original goal
The phase goal described the full flow ticket → triage → MCP investigation → remediation plan with HITL approval, visible in real time. Phase 1 delivered the building blocks of that flow, but **not the integrated flow**:
- There is no Executor Agent or HITL approval.
- The AI engine is not connected to the MCP server (only a `context_provider` injection point).
- The Gateway does not invoke the graph or emit its reasoning: `/ws/stream` is an echo.
- `POST /api/v1/tickets` does not persist (no SQLAlchemy/Alembic/PostgreSQL) and there is no JWT authentication.
- The frontend does not list tickets; it only shows the console.

## 🚀 Next Steps

1. **End-to-end integration (next priority):** real MCP client in the investigator, graph invocation from the Gateway and event emission over `/ws/stream`.
2. **Executor Agent and HITL:** remediation plan with human approval and its modal in the frontend.
3. **Persistence and authentication:** SQLAlchemy models, Alembic migrations and JWT.
4. **Frontend:** ticket table and login.
5. **Base quality:** shared configuration and logging, and a CI pipeline (lint + tests).
6. **Phase 2 (containerization):** Docker Compose, Traefik/Nginx with SSL and CI/CD over SSH. Consider then `HOST=0.0.0.0` in containers and the migration to `mcp` v2.
7. **Known debt:** manual verification of the flow against the real Anthropic API, which was not run in this phase.
