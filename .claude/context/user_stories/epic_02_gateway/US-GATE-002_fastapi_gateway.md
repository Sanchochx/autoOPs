# US-GATE-002: Base API Gateway Implementation in FastAPI

**Epic:** 02 — API Gateway & Communications
**Priority:** CRITICAL
**Estimate:** 5 pts
**Dependencies:** US-MONO-001
**Status:** Completed

---

## User Story

**As** a developer on the AutoOps team,
**I want** a base API Gateway in FastAPI with configurable CORS, initial REST endpoints validated with Pydantic, a streaming WebSocket channel and a local startup script,
**so that** we have the communication backbone on which the frontend and the AI engine will be integrated in the following stories.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: Base FastAPI structure and CORS**
  - `apps/api_gateway/requirements.txt` is created with the dependencies: `fastapi`, `uvicorn[standard]` and `pydantic`.
  - The FastAPI application is initialized in `apps/api_gateway/main.py`.
  - The CORS middleware (`CORSMiddleware`) is configured, reading the allowed origins from an environment variable (`CORS_ALLOWED_ORIGINS`, comma-separated list); no origins hardcoded in the code.
  - If the variable is not defined, the default behavior is restrictive (no origin allowed) rather than opening up with `*`.
  - **Verification:** the app imports without errors and a request with an allowed `Origin` header receives `Access-Control-Allow-Origin`; a disallowed one does not.

- [x] **AC-2: Initial REST endpoints and Pydantic validation**
  - `GET /health` returns `200` with `{"status": "ok", "service": "api_gateway"}`.
  - `POST /api/v1/tickets` receives a Pydantic model `TicketCreate` with the fields `title`, `description` and `severity`.
    - `title` and `description`: non-empty text.
    - `severity`: value restricted to a closed set (enumeration).
  - Returns `201` with the created ticket, including a server-generated UUID4 `id`.
  - An invalid payload returns `422` with the FastAPI/Pydantic validation detail.
  - Pydantic models use strict typing and live outside `main.py` (schemas module).
  - **Verification:** tests with `TestClient` for the valid case (valid UUID4 in `id`) and for invalid cases (missing field, `severity` outside the set, empty text).
  - **Note:** in this US there is no persistence; the ticket is returned without being saved to a database.

- [x] **AC-3: WebSocket endpoint for Streaming**
  - WebSocket route `/ws/stream`.
  - A `ConnectionManager` class is implemented that:
    - Manages the list of active connections (`connect`, `disconnect`).
    - Allows sending a message to a specific connection and broadcasting to all.
    - Handles `WebSocketDisconnect` by removing the connection cleanly, leaving no orphaned connections and not propagating the exception.
  - On connecting, the client receives a confirmation message; the endpoint echoes received messages as the minimum verifiable behavior.
  - Connection and disconnection events are recorded via logging to stdout/stderr.
  - **Verification:** test with `TestClient.websocket_connect` covering connection, message/echo and disconnection (the manager is left with no active connections).

- [x] **AC-4: Local startup script**
  - Startup via Uvicorn reads the host and port from `.env` (`HOST`, `PORT`), with no hardcoded values; defaults are limited to a safe development fallback.
  - The gateway can be brought up with a single documented command from the monorepo root.
  - The new variables introduced in this US (`HOST`, `CORS_ALLOWED_ORIGINS`) are added to `.env.example`, with their section and comment.
  - **Verification:** on startup, `GET /health` responds on the configured port and changing `PORT` in `.env` changes the listening port.

---

## Technical Notes

- **Out of scope:** JWT authentication, persistence (SQLAlchemy/Alembic), integration with the AI engine and MCP servers; all of that belongs to other US in Epic 02 and later.
- **Twelve-Factor:** no URL, port, host or origin is written in the code; everything comes from environment variables.
- **Logging:** stdout/stderr only; no handlers that write or rotate files.
- **Imports:** the package is `apps.api_gateway` (underscore), reference command: `uvicorn apps.api_gateway.main:app`.
- **Conventions:** files and functions in `snake_case`, classes (`TicketCreate`, `ConnectionManager`) in `PascalCase`, REST routes in `kebab-case`.
- **Tests:** located in `tests/` and runnable with `pytest tests/ -v`.
