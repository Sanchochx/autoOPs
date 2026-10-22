# Phase 2 Summary: Logical Integration and Persistence

**Project:** AutoOps — Self-Hosted Multi-Agent SRE Platform
**Closing date:** 2026-10-15
**Status:** Completed (4/4 US)

| US | Epic | Commit |
|----|------|--------|
| US-DB-001 ORM, models and migrations setup | 06 | `c734e2f` |
| US-DB-002 Real persistence and ticket CRUD | 06 | `fcdd971` |
| US-INT-001 Background Triage Agent trigger | 07 | `6000403` (closing `c5551f4`) |
| US-INT-002 AI reasoning streaming via WebSockets | 07 | `b3750c3` |

---

## 📝 Changes Made

- **Persistence:** asynchronous PostgreSQL (SQLAlchemy + asyncpg), `Ticket` model and initial Alembic migration. `docker-compose.yml` starts the local database with credentials from the environment.
- **Ticket CRUD:** persistent REST endpoints under `/api/v1/tickets`, tested with a simulated session.
- **AI trigger:** `POST /api/v1/tickets` saves the ticket (`severity=medium`, `status=open`), responds `201` and enqueues triage with `BackgroundTasks`.
- **AI service (`ai_service.py`):** `process_ticket_with_ai` opens its own session, runs the graph and updates `severity` and `status=investigating`. On failure it keeps the previous state and does not propagate the exception.
- **Streaming:** the graph is consumed with `astream(stream_mode="updates")` and each node emits a JSON event `{"type":"ai_event","ticket_id","node","message"}` via global broadcast.

## 📂 Files Modified/Created

| Path | Purpose |
|------|---------|
| `apps/api_gateway/{database,models}.py`, `alembic/` | Asynchronous connection, `Ticket` model and migrations |
| `apps/api_gateway/routers/tickets.py` | CRUD and triage enqueueing |
| `apps/api_gateway/services/ai_service.py` | Invocation, streaming and post-triage persistence |
| `tests/test_ai_service.py`, `tests/test_rest_endpoints.py` | Tests with simulated graph, session and `ConnectionManager` (27 tests in total) |
| `.env.example` | `DATABASE_URL`, `WS_BROADCAST_TIMEOUT_SECONDS`, `PYTHONPATH` |

## 🎯 Rationale

- **What was completed and why:** the flow ticket → AI triage → persistence → real-time events works end to end and was validated manually (DB, LangSmith and `wscat`).
- **Design decisions:**
  - **Own session in the background task:** the request session is already closed.
  - **Isolation:** the AI engine does not touch PostgreSQL; the Gateway reads and writes the ticket and only passes data to the graph.
  - **Fault-tolerant emission:** `broadcast` with a configurable timeout; a slow or dropped client does not stop triage.
  - **Global broadcast:** the frontend filters by `ticket_id`.
  - **Injectable dependencies** (`graph`, `session_factory`, `ws_manager`) to test without an LLM or network.

### Delivered scope versus the original goal
The goal mentioned the **Executor Agent with HITL**, which was **not implemented**. Also missing are:
- The real MCP client in the investigator (only the `context_provider` injection point).
- JWT authentication.
- Consumption of `ai_event` events and the ticket table in the frontend.
- The AI Engine is still a library imported in-process by the Gateway, not a service.

## 🚀 Next Steps

1. **Phase 3 (containerization):** Epic 08, US-DOCK-001 (multi-stage builds). Open decision: AI Engine as a library inside the Gateway image (A) or as an independent service (B).
2. **Product backlog:** Executor Agent and HITL, real MCP client, JWT and `ai_event` consumption in the frontend; they must be assigned to a phase.
3. **Migrations:** define how Alembic runs in a container.
