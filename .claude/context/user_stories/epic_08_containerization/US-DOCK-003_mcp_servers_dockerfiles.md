# US-DOCK-003: Dockerfiles for the MCP Servers

**Epic:** 08 — Containerization & Orchestration
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** US-DOCK-001 (build conventions and non-root user), US-MCP-003
**Status:** Completed

---

## User Story

**As** a DevOps engineer,
**I need** to package each MCP server in its own minimal, hardened image,
**so that** access to logs, metrics and infrastructure tools is isolated from the rest of the platform and reachable only through the authorized network.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: Logs Server Network Transport**
  - Resolve the open decision (see Technical Notes) and adapt `services/mcp-servers/logs_server/server.py` so that it is reachable over the network inside a container, reading host and port exclusively from the environment.
  - Preserve the existing tools (`get_system_logs`, `get_db_metrics`) and the logs to stderr/stdout.
  - **Verification:** the server starts locally with the new transport and an MCP client lists and runs its tools.

- [x] **AC-2: Logs Server Image**
  - Create a multi-stage `services/mcp-servers/logs_server/Dockerfile` (`builder` + `runtime` on a pinned `python:3.11-slim`) that installs only `services/mcp-servers/logs_server/requirements.txt`, with dependency layers before the code.
  - Run as a non-root user and without secrets in the layers; this server requires neither DB credentials nor AI keys.
  - **Verification:** `docker build` without errors; `docker run` brings up the server and an MCP client on the host runs `get_system_logs`; `id -u` ≠ `0`.

- [x] **AC-3: Hardening and Isolation**
  - Document and prepare (for application in Compose) the container's runtime restrictions: read-only root filesystem, `cap_drop: [ALL]`, `no-new-privileges`, no ports published to the host and no access to the network of the rest of the services except the MCP network.
  - Leave a template/convention (folder structure and base Dockerfile) for adding the future DB MCP server (`MCP_DB_SERVER_URL`) without duplicating logic.
  - **Verification:** the image starts correctly with `--read-only --cap-drop ALL --security-opt no-new-privileges`; final size recorded in the US summary.

---

## Technical Notes

- **Closed decision (SSE, indicated by the user; variant of option A):** the server uses `mcp.run(transport="sse")` (endpoint `/sse`). The AI Engine client does not yet consume MCP, so it required no changes. Original context: today `logs_server` uses the **stdio** transport (`mcp.run(transport="stdio")`), meant to be launched as a subprocess by the client. In separate containers it is not reachable over the network, and `.env.example` already defines `MCP_LOGS_SERVER_URL` (HTTP). Options:
  - **A) HTTP transport (streamable-http) in the server:** real network isolation, consistent with `MCP_LOGS_SERVER_URL`. Requires adjusting the server and checking how the AI Engine client connects (today it does so via stdio).
  - **B) Keep stdio:** the AI Engine would launch the server as a subprocess inside the same image; there is no runtime isolation, which contradicts the goal of this US.
  - Recommendation: A. If the AI Engine client needs changes to connect over HTTP, keep them to a minimum and document them.
- **DB MCP server:** it does not exist yet (only its `MCP_DB_SERVER_URL` variable); creating it is out of scope. This US only ensures that adding it is trivial.
- **Out of scope:** services in `docker-compose.yml` and networks (US-DOCK-004), new MCP tools, authentication between MCP client and server (to be evaluated in Phase 4).
- **Isolation principle:** the MCP servers are the only path to the infrastructure; their images include neither LangGraph nor Gateway code.
- **Logging:** stdout/stderr, with no files or log volumes.
- **Conventions:** named stages (`builder`, `runtime`); pinned base image versions (no `latest`); `pip --no-cache-dir`.

---

## Closing Summary

- **Transport:** HTTP + SSE (`mcp.run(transport="sse")`, endpoints `/sse` and `/messages/`). SSE is kept for now; `streamable-http` is noted for future iterations.
- **Image:** `autoops-mcp-logs`, `python:3.11-slim`, multi-stage (`builder` + `runtime`), non-root user `10001`. **Final size: 282 MB.**
- **Verified security restrictions:** `--read-only`, `--cap-drop ALL`, `--security-opt no-new-privileges`; no secrets in layers; no ports published in Compose (only `expose`). Application in Compose: US-DOCK-004.
- **Configuration:** `MCP_LOGS_HOST` / `MCP_LOGS_PORT` from the environment (the port is mandatory); client URL `MCP_LOGS_SERVER_URL` (ends in `/sse`).
- **Convention for new servers:** `services/mcp-servers/README.md`.
