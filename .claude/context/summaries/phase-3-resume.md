# Phase 3 Summary: Advanced Containerization

**Project:** AutoOps — Self-Hosted Multi-Agent SRE Platform
**Closing date:** 2026-10-18
**Status:** Completed (4/4 US)

| US | Epic | Commit |
|----|------|--------|
| US-DOCK-001 Multi-stage builds for API Gateway and AI Engine | 08 | `359ec92` |
| US-DOCK-002 Multi-stage Dockerfile for the Frontend (Vite + Nginx) | 08 | `41c855e` |
| US-DOCK-003 Dockerfiles for the MCP servers (SSE transport) | 08 | `efc7f62` |
| US-DOCK-004 Global orchestration with Docker Compose | 08 | `35e3889` |

---

## 📝 Changes Made

- **Images:** multi-stage, pinned versions and a non-root user in `api-gateway`, `frontend` (unprivileged Nginx, port 8080) and `mcp-logs`.
- **MCP server:** refactored from stdio to **SSE** transport so it can live in its own container; the Gateway consumes it at `http://mcp-logs:<MCP_LOGS_PORT>/sse`.
- **AI Engine:** still runs in-process inside the Gateway image (decision A of US-DOCK-001); it is not a Compose service.
- **Orchestration:** `docker-compose.yml` starts `postgres`, `mcp-logs`, `api-gateway` and `frontend` with a single `docker compose up -d --build`. All configuration comes from `.env`, with `${VAR:?message}` for the mandatory ones.
- **Migrations:** ephemeral `migrate` service under the `tools` profile (`docker compose --profile tools run --rm migrate`); the Gateway never migrates on startup.
- **Health and startup:** per-service `healthcheck` and `depends_on: service_healthy` (the Gateway waits for Postgres and MCP; the Frontend waits for the Gateway). `restart: unless-stopped`; logs to the default driver (stdout/stderr).

## 🌐 Network Topology

| Network | `internal` | Members | Purpose |
|---------|-----------|---------|---------|
| `frontend_net` | no | `frontend`, `api-gateway` | Publishing to the host and Internet egress (the Gateway calls the AI provider) |
| `backend_net` | **yes** | `api-gateway`, `postgres`, `migrate` | Data access; no Internet or host |
| `mcp_net` | **yes** | `api-gateway`, `mcp-logs` | MCP tools; no Internet or host |

- Only `frontend` (`FRONTEND_PORT`) and `api-gateway` (`PORT`) publish ports. **Today they do so on all interfaces (`0.0.0.0`)**.
- `postgres` **does not publish ports** in the base compose. Loopback binding is optionally obtained with `docker-compose.dev-db.yml`, which attaches it to `db_host_net` (`internal` networks do not support `ports:`). Development only.
- `mcp-logs` is reachable only from the Gateway; it sees neither Postgres nor the Internet.

## 📂 Files Modified/Created

| Path | Purpose |
|------|---------|
| `docker-compose.yml` | Full orchestration, networks, healthchecks, hardening (`cap_drop: ALL`, `no-new-privileges`, `read_only`, `tmpfs`) |
| `docker-compose.dev-db.yml` | Optional override to expose Postgres on loopback (development) |
| `apps/api_gateway/Dockerfile`, `apps/frontend/Dockerfile` (+ `nginx.conf`), `services/mcp-servers/logs_server/Dockerfile` | Multi-stage non-root images |
| `.env.example` | Published ports, `DATABASE_URL`, `CORS_ALLOWED_ORIGINS`, `VITE_*` (build-args), `AI_MODEL_NAME`, etc. |

## 🎯 Rationale

- **Layered isolation:** the two `internal` networks mean a compromised container (e.g. the MCP) cannot exfiltrate over the network or reach the database; only the Gateway joins the three worlds.
- **Hardening by default:** `cap_drop: ALL` with minimal exceptions (Postgres needs `CHOWN/DAC_OVERRIDE/FOWNER/SETGID/SETUID`), read-only filesystem and `no-new-privileges`.
- **Explicit migrations:** avoids races between replicas and keeps Gateway startup free of side effects on the schema.
- **Twelve-Factor:** no hardcoded credentials, URLs or ports; the `VITE_*` variables are build-time and must be reachable from the browser.
- **Validation:** full stack tested locally (green healthchecks, WebSocket streaming and MCP connection over SSE end to end).

## 🚀 Next Steps

**Phase 4: Linux Infrastructure and Security** (dedicated Ubuntu Server 24.04 LTS, validated on a clean VirtualBox VM; EC2 is only the final target).

- **Decisions made:** provisioning with **idempotent Bash scripts** + `verify.sh` (no Ansible); **standard Docker Engine** with a hardened `daemon.json` (no rootless, so as not to complicate low ports in Phase 5); `auditd`/Lynis **out of scope**.
- **Concerns inherited from this phase:**
  1. Docker publishes `PORT` and `FRONTEND_PORT` bypassing UFW (`DOCKER-USER` chain): resolved in US-NET-002.
  2. The stack must start on its own after a host reboot: US-SYS-003 (systemd).
  3. `.env` contains plaintext secrets: `0600` permissions and `autoops` owner (US-HOST-001).
  4. No backups of `postgres_data`: US-SYS-004.
- **Phase 5 (later):** Traefik/Nginx + Let's Encrypt and GitHub Actions over SSH, relying on the restricted deploy key and the firewall from Phase 4.
- **Product debt with no assigned phase:** Executor Agent/HITL, JWT and a real MCP client in the investigator.
