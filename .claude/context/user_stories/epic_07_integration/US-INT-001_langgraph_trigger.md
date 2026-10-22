# US-INT-001: Background Triage Agent Trigger

**Epic:** 07 — AI Integration
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** US-DB-002, US-LANG-004
**Status:** Completed

---

## User Story

**As** an orchestrator,
**I need** the API Gateway to launch the LangGraph engine in the background when a new ticket is created (`POST`) so that the Triage Agent assigns the real severity,
**so that** incidents are classified automatically without blocking the HTTP response to the client.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: FastAPI Background Tasks**
  - Modify `POST /api/v1/tickets` to inject FastAPI's `BackgroundTasks`.
  - The endpoint must save the ticket in the DB with initial severity `medium` and status `open`, enqueue the AI task and respond immediately with `201`.
  - **Verification:** the `201` response arrives without waiting for the graph; the ticket is left in the DB with `severity=medium` and `status=open`; the AI task is enqueued with the created `ticket_id`.

- [x] **AC-2: LangGraph Invocation Service**
  - Create `apps/api_gateway/services/ai_service.py`.
  - Create the async function `process_ticket_with_ai(ticket_id, db_session)` that looks up the ticket in the database and calls the compiled graph (`compiled_graph.invoke()`).
  - **Verification:** with an existing `ticket_id`, the service loads the ticket and invokes the graph with its content; with a nonexistent ID, it finishes without invoking the graph and without propagating the exception.

- [x] **AC-3: Post-Triage Update**
  - When the LangGraph execution finishes, take the resulting state (`AgentState`) and use it to update the ticket's `severity` in the database and change its `status` to `investigating`.
  - **Verification:** after the task, the persisted ticket has the `severity` returned by the Triage Agent and `status=investigating`; if the graph fails, the ticket keeps `severity=medium` and `status=open` and the error is logged to stdout/stderr.

---

## Technical Notes

- **Out of scope:** the Executor Agent and the HITL flow, reasoning streaming over WebSocket, retries and external queues (Celery, Redis), and JWT authentication.
- **Task's own session:** the `Depends(get_db_session)` session is closed when the request ends; the background task must open its own session (e.g. with `get_session_factory()`) and not reuse the request's. This is a decision to close before implementing `process_ticket_with_ai(ticket_id, db_session)`.
- **Synchronous graph:** `compiled_graph.invoke()` is blocking; run it with `asyncio.to_thread` (or use `ainvoke`) so as not to block the event loop. This is a decision to close before implementing.
- **MCP isolation:** the AI engine never connects directly to PostgreSQL; the Gateway reads and writes the ticket and only passes data to the graph.
- **Tests:** keep the `dependency_overrides` strategy with an `AsyncMock` session and simulate `compiled_graph` with a mock; no real LLM is invoked in the tests.
- **Logging:** background task errors are emitted to stdout/stderr, with no local files.
- **Twelve-Factor:** no API keys or URLs in the code; everything from environment variables.
- **Conventions:** files and functions in `snake_case`, classes in `PascalCase`.
