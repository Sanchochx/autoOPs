# US-INT-002: AI Reasoning Streaming via WebSockets

**Epic:** 07 — AI Integration
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** US-INT-001, US-GATE-002 (WebSocket and `ConnectionManager`)
**Status:** Completed

---

## User Story

**As** a dashboard user,
**I need** to see in real time what the AI is thinking and doing while it processes a ticket,
**so that** I can understand the agent's reasoning as it happens, by sending LangGraph events through the API Gateway's WebSocket.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: LangGraph Event Capture**
  - Modify `process_ticket_with_ai` in `apps/api_gateway/services/ai_service.py` to use LangGraph's streaming mode (`.astream_events()` or `.astream()`) instead of the single blocking invocation (`invoke()`).
  - Preserve the behavior of US-INT-001: the final state feeds the `severity` and `status` update, and failures leave the ticket at `medium`/`open`.
  - **Verification:** with a simulated graph that emits several events, the service consumes them all in order and obtains the same final state as with `invoke()`.

- [x] **AC-2: WebSocket Emission**
  - Connect the AI's async event generator to the WebSocket `ConnectionManager` created in Phase 1.
  - Send JSON messages to the frontend for each significant agent step (e.g. "Starting triage", "Evaluating severity...", "Updating database").
  - **Verification:** with WebSocket clients connected, each significant step produces a valid JSON message with the `ticket_id` and the step description; with no clients connected, no error occurs.

- [x] **AC-3: Gateway Non-Blocking**
  - Ensure that WebSocket event emission stays inside the `BackgroundTask` without interrupting the async experience.
  - **Verification:** the `201` response of `POST /api/v1/tickets` still does not wait for the graph; a slow or disconnected WebSocket client neither stops nor causes the ticket processing to fail.

---

## Technical Notes

- **Out of scope:** the Executor Agent and the HITL flow, consumption of the events in the frontend, retries, external queues (Celery, Redis) and JWT authentication.
- **GATE dependency:** the `ConnectionManager` and the WebSocket endpoint (`apps/api_gateway/connection_manager.py`, `routers/ws.py`) come from US-GATE-002; there is no US-GATE-003 in the plan.
- **Closed decisions:**
  - **JSON message contract:** `{"type": "ai_event", "ticket_id": "<uuid>", "node": "<node_name>", "message": "<action description>"}`.
  - **Connection strategy:** global broadcast with the existing `ConnectionManager`; the frontend filters by `ticket_id`.
  - **Streaming method:** `compiled_graph.astream(..., stream_mode="updates")`; an event is emitted for each node that finishes.
- **MCP isolation:** the AI engine never connects directly to PostgreSQL; the Gateway reads and writes the ticket and only passes data to the graph.
- **Tests:** keep `dependency_overrides` and mocks; simulate the graph with an async event generator and the `ConnectionManager` with a mock; no real LLM is invoked in the tests.
- **Logging:** errors are emitted to stdout/stderr, with no local files.
- **Twelve-Factor:** no API keys or URLs in the code; everything from environment variables.
- **Conventions:** files and functions in `snake_case`, classes in `PascalCase`.
