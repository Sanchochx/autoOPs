# US-DOCK-004: Global Orchestration with Docker Compose

**Epic:** 08 — Containerization & Orchestration
**Priority:** HIGH
**Estimate:** 8 pts
**Dependencies:** US-DOCK-001, US-DOCK-002, US-DOCK-003
**Status:** Completed

---

## User Story

**As** a DevOps engineer,
**I need** to bring up the whole platform (PostgreSQL, API Gateway, MCP servers and Frontend) with a single `docker compose up`,
**so that** I have a reproducible environment with isolated networks, persistent data and a correct startup order, identical on a local VM and on AWS EC2.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: Services and Per-Environment Configuration**
  - Extend `docker-compose.yml` (currently only PostgreSQL) with the `api-gateway`, `mcp-logs`, `frontend` services and the existing `postgres`, using the `build:` entries from US-DOCK-001/002/003 (context at the monorepo root).
  - All configuration is injected via `env_file`/`environment:` from `.env`; no hardcoded credentials or ports. Document the new variables in `.env.example` (e.g. published ports, `DATABASE_URL` pointing to the `postgres` service).
  - **Verification:** `docker compose config` validates with no errors or undefined variables.

- [x] **AC-2: Isolated Bridge Networks**
  - Define separate `bridge` networks by responsibility: a frontend network (publishes only what is necessary to the host), a backend network (`api-gateway` ↔ `postgres`, `internal: true`) and an MCP network (`api-gateway` ↔ MCP servers, `internal: true`).
  - Only `frontend` and `api-gateway` publish ports to the host; `postgres` keeps the binding to `127.0.0.1` and the MCP servers publish nothing. Apply the hardening defined in US-DOCK-003 (`read_only`, `cap_drop`, `no-new-privileges`).
  - **Verification:** from the Gateway container, `postgres` and `mcp-logs` are reachable; `mcp-logs` reaches neither `postgres` nor the Internet; the host cannot access the MCP servers.

- [x] **AC-3: Persistent Volumes and Migrations**
  - Keep the named volume `postgres_data` and ensure the data survives `docker compose down` (without `-v`).
  - Add an explicit, reproducible step to run the Alembic migrations (ephemeral `migrate` service with `profiles` or `docker compose run --rm`), not run automatically when the Gateway starts.
  - **Verification:** after `down` and `up`, the tickets created earlier still exist; the migration command leaves the schema at `head`.

- [x] **AC-4: Startup Order and Health (`depends_on`)**
  - Define a `healthcheck` on `postgres`, `api-gateway` (`/health`) and the MCP servers, and use `depends_on` with `condition: service_healthy` (Gateway waits for Postgres and MCP; Frontend waits for the Gateway).
  - Configure `restart: unless-stopped` and logs to stdout/stderr (default driver, no log volumes).
  - **Verification:** `docker compose up -d --build` brings everything up in order with all services `healthy`; the full flow (create ticket → AI streaming over WebSocket in the dashboard) works end to end.

---

## Technical Notes

- **Out of scope:** Traefik/Nginx as reverse proxy with SSL and Let's Encrypt (Phase 5), CI/CD and deployment over SSH (Phase 5), Ubuntu host hardening (Phase 4), secrets management with Docker secrets/vault.
- **AI Engine:** it currently runs in-process inside the Gateway (decision A of US-DOCK-001); therefore it is not a Compose service and the Gateway needs access to the MCP network. If it is isolated as a service (decision B), this US will be updated.
- **Frontend:** the `VITE_*` variables are fixed at build time; `build:` must pass `args` from `.env` and the Gateway's public URL must be reachable from the browser (not an internal service name).
- **CORS:** `CORS_ALLOWED_ORIGINS` must include the frontend's published origin.
- **`internal: true` networks:** no Internet egress; the Gateway needs egress to call the AI provider, so it must also belong to a network with egress (the frontend/publishing one).
- **Conventions:** service names in `kebab-case`; pinned image versions; one `healthcheck` per service.
