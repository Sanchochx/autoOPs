# US-NET-002: Docker ↔ UFW Coherence

**Epic:** 10 — Network Security
**Priority:** CRITICAL
**Estimate:** 5 pts
**Dependencies:** US-NET-001, US-SYS-002
**Status:** Completed

---

## User Story

**As** the server administrator,
**I need** the ports published by Docker to respect the host firewall rules,
**so that** no container is exposed to the Internet by a forgotten `ports:` entry, even if UFW denies it.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is done and pause at the final checkpoint before closing the US.

- [x] **AC-1: Reproduce and Document the Leak**
  - With Docker and UFW active and the stack up, demonstrate from another machine (or from the VirtualBox host) that `PORT` and `FRONTEND_PORT` are reachable even though UFW does not allow them.
  - Document the cause (Docker inserts its NAT/FORWARD rules before UFW's) in `infra/firewall/README.md`.
  - **Verification:** capture of the command and result (`nmap`/`curl`) showing the exposure.

- [x] **AC-2: Filtering in the `DOCKER-USER` Chain**
  - Managed block in `/etc/ufw/after.rules` (template in `infra/firewall/`, applied by `scripts/provision/45_docker_ufw.sh`) that, in `DOCKER-USER`, drops incoming traffic from the external interface to containers except for allowed ports (80/443 and whichever are decided), without breaking inter-container traffic or return traffic (`ESTABLISHED,RELATED`).
  - Keep Docker-managed `iptables` (do not disable it with `"iptables": false`) so the compose `internal` networks do not break.
  - **Verification:** after reloading UFW and restarting Docker, unauthorized ports are unreachable from outside and still work from the host itself.

- [x] **AC-3: Explicit Decision on Gateway and Frontend**
  - Document and apply which ports stay public until Phase 5: recommended, the frontend via a provisional `FRONTEND_PORT` and the Gateway only on loopback or behind the proxy. Any change to `docker-compose.yml` (e.g. binding to `127.0.0.1`) is parameterized by variable and noted in `.env.example`.
  - **Verification:** the end-to-end flow (create ticket → WebSocket streaming) still works from the browser using only the allowed ports.

- [x] **AC-4: External Scan and Check**
  - Check `scripts/provision/checks/45_docker_ufw.sh` (`DOCKER-USER` rules present and persistent after reboot) and a documented external `nmap` scan procedure.
  - **Verification:** the scan shows only SSH, 80 and 443 (and whatever is defined in AC-3); the result is attached to the documentation.

---

## Technical Notes

- **Order:** requires Docker installed (US-SYS-002) and UFW active (US-NET-001).
- **`internal` networks:** `backend_net` and `mcp_net` must not be affected; verify with the stack healthy after the change.
- **Out of scope:** reverse proxy, TLS (Phase 5), advanced IPv6.
