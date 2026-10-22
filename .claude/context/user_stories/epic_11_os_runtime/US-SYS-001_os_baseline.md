# US-SYS-001: OS Baseline and Automatic Patching

**Epic:** 11 — OS Hardening & Runtime
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** US-HOST-001
**Status:** Completed

---

## User Story

**As** the server administrator,
**I need** a minimal, time-synchronized base system that receives security patches without intervention,
**so that** the attack surface is reduced and known vulnerabilities are avoided without manual maintenance.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is done and pause at the final checkpoint before closing the US.

- [x] **AC-1: Minimal Packages and Unnecessary Services**
  - Idempotent script `scripts/provision/50_os_baseline.sh`: update the index and the system, install only the necessary tools and review listening services (`ss -tulpn`), disabling those not required.
  - **Verification:** the list of listening ports after the script is only SSH (plus the expected internal systemd ones) and is documented.

- [x] **AC-2: Automatic Security Patches**
  - `unattended-upgrades` configured for the security channel only, with a documented reboot policy (no automatic reboot by default; optional window via variable).
  - **Verification:** `unattended-upgrade --dry-run` works and the `apt-daily-upgrade` timer is active.

- [x] **AC-3: Time Synchronization**
  - `chrony` installed and active (logs and JWT tokens depend on correct time); UTC timezone via variable.
  - **Verification:** `chronyc tracking` shows synchronization.

- [x] **AC-4: Kernel Parameters (`sysctl`) and Verification**
  - Drop-in `/etc/sysctl.d/99-autoops.conf` (template in `infra/sysctl/`): `tcp_syncookies`, `rp_filter`, rejection of `source route` and ICMP redirects, `kernel.kptr_restrict`, `kernel.dmesg_restrict`, `fs.protected_hardlinks/symlinks`, etc. **Without** disabling `ip_forward` (Docker needs it).
  - Check `scripts/provision/checks/50_os_baseline.sh` with the expected values.
  - **Verification:** `sysctl --system` applies without errors and the check passes; the Compose stack remains operational.

---

## Technical Notes

- **Out of scope:** auditd, Lynis, custom AppArmor/seccomp, disk encryption.
- **Idempotency:** re-running the script must not reinstall packages or duplicate configurations.
