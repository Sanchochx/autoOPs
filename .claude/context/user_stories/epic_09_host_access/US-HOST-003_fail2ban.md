# US-HOST-003: Brute-Force Protection (fail2ban)

**Epic:** 09 — Host Access & Identity
**Priority:** HIGH
**Estimate:** 3 pts
**Dependencies:** US-HOST-002
**Status:** Completed

---

## User Story

**As** the server administrator,
**I need** to automatically block IPs that try to guess SSH credentials,
**so that** noise and the risk of persistent attacks against the exposed port are reduced.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is done and pause at the final checkpoint before closing the US.

- [x] **AC-1: Installation and sshd Jail**
  - Idempotent script `scripts/provision/30_fail2ban.sh` that installs `fail2ban` and deploys `jail.d/autoops.local` (template in `infra/fail2ban/`) with the `sshd` jail active, `backend = systemd` (reads journald, no log files) and the port taken from the SSH variable.
  - **Verification:** `fail2ban-client status sshd` shows the jail active.

- [x] **AC-2: Ban Policy and Allowlist**
  - Parameters via environment variable: `maxretry`, `findtime`, `bantime` (with progressive increment) and `ignoreip` for the admin IP/CIDR and the VM's local network.
  - **Verification:** 3-5 failed attempts from an IP not included in `ignoreip` trigger a ban; the `ignoreip` IP is never blocked.

- [x] **AC-3: Firewall-Compatible Ban Action and Verification**
  - Leave the ban action ready for UFW (`banaction = ufw`) or document compatibility with US-NET-001, so both pieces do not step on each other.
  - Check `scripts/provision/checks/30_fail2ban.sh` (service active, jail loaded, `ignoreip` present).
  - **Verification:** the check passes; `fail2ban-client set sshd unbanip <ip>` reverts a ban.

---

## Technical Notes

- **Cloud-native logging:** fail2ban reads from journald; no log files of its own are configured.
- **Out of scope:** jails for Traefik/Nginx (Phase 5), email notifications.
