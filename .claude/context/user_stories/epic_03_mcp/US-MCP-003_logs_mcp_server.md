# US-MCP-003: MCP Server for Simulated Log and Metrics Inspection

**Epic:** 03 — MCP Servers
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** US-GATE-002
**Status:** Completed

---

## User Story

**As** an AI orchestrator,
**I need** a Model Context Protocol (MCP) server that exposes safe tools to query logs and metrics,
**so that** the Investigator Agent can inspect the system state without direct access to the infrastructure.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: MCP Server structure**
  - The folder `services/mcp-servers/logs_server/` is created.
  - `requirements.txt` is created with the official `mcp` library (Anthropic SDK), using its `FastMCP` (`mcp.server.fastmcp`) to declare tools with decorators.
  - `server.py` is created, initializing the MCP server, ready for standard communication via `stdio`.
  - **Verification:** `server.py` imports without errors and the server is instantiated with an identifiable name.

- [x] **AC-2: `get_system_logs` tool**
  - An MCP tool is exposed that receives the argument `service_name` (e.g. `"api_gateway"`, `"database"`).
  - Returns an array (or string) with 5 simulated recent error/info-level log lines for that service.
  - **Verification:** when invoked with a valid service it returns exactly 5 lines that reference that service.

- [x] **AC-3: `get_db_metrics` tool**
  - An MCP tool with no arguments is exposed.
  - Returns a simulated JSON payload with the database health: active connections, CPU usage and slow transactions.
  - **Verification:** the response is valid JSON and contains the three indicated fields.

- [x] **AC-4: Runtime configuration**
  - `server.py` includes the `if __name__ == "__main__":` block that starts the server over `stdio`.
  - The server is ready to be launched as a subprocess by a client (for example, LangGraph).
  - **Verification:** `python services/mcp-servers/logs_server/server.py` starts and waits on stdio without errors.

---

## Technical Notes

- **Isolation (MCP):** the server does not connect to PostgreSQL or run OS commands; data is simulated in this US.
- **Logging:** stdout/stderr only. With the `stdio` transport, stdout is the protocol channel: diagnostic logs must go to **stderr**.
- **Twelve-Factor:** no credentials, URLs or ports in the code; any new variable is documented in `.env.example`.
- **Out of scope:** real connection to logs/metrics, integration with the AI engine, HTTP/SSE transport.
- **Conventions:** files and functions in `snake_case`.
