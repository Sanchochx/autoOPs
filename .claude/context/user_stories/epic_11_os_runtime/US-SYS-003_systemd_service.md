# US-SYS-003: systemd Service for the AutoOps Stack

**Epic:** 11 — OS Hardening & Runtime
**Priority:** HIGH
**Estimate:** 8 pts
**Dependencies:** US-HOST-001, US-SYS-002, US-NET-002
**Status:** Pending

---

## User Story

**As** the server administrator,
**I need** the platform to start, stop and restart as a native systemd service,
**so that** AutoOps recovers on its own after a host reboot and is operated with standard Linux tools.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is done and pause at the final checkpoint before closing the US.

- [ ] **AC-1: `autoops.service` Unit**
  - Unit (template in `infra/systemd/`, installed by `scripts/provision/70_systemd.sh`): `Type=oneshot`, `RemainAfterExit=yes`, `User=autoops`, `WorkingDirectory=/opt/autoops`, `After=docker.service network-online.target`, `Requires=docker.service`.
  - `ExecStart=docker compose up -d`, `ExecStop=docker compose down` (without `-v`: data persists) and optional `ExecReload`; `TimeoutStartSec` consistent with the healthchecks.
  - **Verification:** `systemctl start/stop/restart autoops` works and the stack ends up `healthy`.

- [ ] **AC-2: Unit Configuration and Sandboxing**
  - `EnvironmentFile`/`.env` in `/opt/autoops` (mode `0600`), no secrets in the unit. Docker-compatible isolation directives: `NoNewPrivileges=yes`, `ProtectHome=yes`, `PrivateTmp=yes`, `ProtectSystem=full` and bounded `ReadWritePaths`. Review with `systemd-analyze security autoops`.
  - **Verification:** the unit starts with sandboxing active and the `systemd-analyze security` score is documented.

- [ ] **AC-3: Migrations as a Manual Oneshot**
  - `autoops-migrate.service` (`Type=oneshot`, no `[Install]`, never enabled at boot) that runs `docker compose --profile tools run --rm migrate`, invocable with `systemctl start autoops-migrate`.
  - **Verification:** the command leaves the Alembic schema at `head`; `autoops.service` does not run it.

- [ ] **AC-4: Boot Startup and Resilience**
  - `systemctl enable autoops` and verification of the restart policy (Compose's `restart: unless-stopped` plus `live-restore`).
  - Check `scripts/provision/checks/70_systemd.sh` (unit enabled, active and services `healthy`).
  - **Verification:** after `sudo reboot` of the VM, the stack comes back `healthy` without intervention and previous tickets still exist.

---

## Technical Notes

- **Logs:** `journalctl -u autoops` for the lifecycle; application logs remain in `docker compose logs` (stdout/stderr).
- **`autoops` user:** needs access to the Docker socket (`docker` group), the only case allowed by US-HOST-001.
- **Out of scope:** advanced health-watchdog, failure notifications, deployment from CI/CD (Phase 5).
