# US-NET-001: UFW Firewall with Deny-by-Default Policy

**Epic:** 10 — Network Security
**Priority:** CRITICAL
**Estimate:** 5 pts
**Dependencies:** US-HOST-002
**Status:** Completed

---

## User Story

**As** the server administrator,
**I need** a host firewall that denies all incoming traffic except what is explicitly authorized,
**so that** only SSH and the planned web ports are exposed and any other service is unreachable from the network.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is done and pause at the final checkpoint before closing the US.

- [x] **AC-1: Default Policy and Secure SSH Access**
  - Idempotent script `scripts/provision/40_ufw.sh`: `default deny incoming`, `default allow outgoing`, `default deny routed`.
  - Allow SSH with `ufw limit` (rate limiting) on the port read from the same variable used in US-HOST-002, **before** enabling the firewall.
  - **Verification:** with UFW active, the existing SSH session is kept and a new connection works; all other incoming ports are closed.

- [x] **AC-2: Web Ports Prepared for Phase 5** _(opening of 80/443 deferred to Phase 5: today it is opt-in with `UFW_WEB_PORTS`; `ADMIN_CIDR` implemented)_
  - Allow `80/tcp` and `443/tcp` (ports configurable by variable) for the future reverse proxy; document that the other ports published by Docker are not opened here.
  - Option to restrict the SSH source to a CIDR (`ADMIN_CIDR`) when defined.
  - **Verification:** `ufw status verbose` shows only the expected rules.

- [x] **AC-3: Logging and Verification**
  - `ufw logging low` (records go to journald/kernel, no application-owned files).
  - Check `scripts/provision/checks/40_ufw.sh`: UFW active, default policy and exact expected rules.
  - **Verification:** the check passes; adding a foreign rule makes it fail.

---

## Technical Notes

- **Known limitation:** UFW does **not** filter ports published by Docker (the Gateway's `PORT` and `FRONTEND_PORT` remain reachable from outside). This is resolved in US-NET-002; until then the exposure is not considered closed.
- **Lockout risk:** always enable UFW after allowing SSH; keep the VirtualBox console as recovery.
- **Out of scope:** advanced IPv6, restrictive outbound rules (egress filtering), WAF.
