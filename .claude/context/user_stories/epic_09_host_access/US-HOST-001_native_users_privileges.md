# US-HOST-001: Native Users and Privilege Model

**Epic:** 09 — Host Access & Identity
**Priority:** CRITICAL
**Estimate:** 5 pts
**Dependencies:** US-DOCK-004
**Status:** Completed

---

## User Story

**As** the Ubuntu server administrator,
**I need** to separate the human administration identity from the service identity that runs AutoOps, with minimal privileges,
**so that** neither a compromised interactive access nor a platform process has more power than necessary.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is done and pause at the final checkpoint before closing the US.

- [x] **AC-1: Admin User and Locked Root**
  - Idempotent script `scripts/provision/10_users.sh` that creates a named admin user (name via environment variable, e.g. `ADMIN_USER`) in the `sudo` group.
  - Lock the `root` password (`passwd -l root`); `sudo` requires a password (no `NOPASSWD` except where strictly necessary and documented).
  - **Verification:** `su -` as root fails; the admin runs `sudo -v`; re-running the script produces no changes or errors.

- [x] **AC-2: `autoops` Service User**
  - Create system user `autoops` (`--system`, no password, shell `/usr/sbin/nologin`, no SSH access) with home/ownership at `/opt/autoops`.
  - Fixed and documented UID/GID so they match across reboots and re-provisioning.
  - **Verification:** `su - autoops` and SSH login fail; `/opt/autoops` is owned by `autoops:autoops` with mode `750`.

- [x] **AC-3: Code and Secrets Permissions**
  - The repository is deployed at `/opt/autoops`; the `.env` file is `autoops:autoops` with mode `0600`. No secrets in files readable by "others".
  - Default `umask 027` for the service user and a minimum password policy (`pwquality`) for the admin.
  - **Verification:** `stat` confirms the modes; a third unprivileged user cannot read `.env` or `/opt/autoops`.

- [x] **AC-4: Docker Access Policy and Verification**
  - Decide and document who operates Docker: membership in the `docker` group is equivalent to `root`, so **only** the `autoops` user (run by systemd, US-SYS-003) and the admin via `sudo` will use it; the admin is not added to the `docker` group.
  - Create `scripts/provision/checks/10_users.sh` with the checks for AC-1..AC-3 (`OK`/`FAIL` output per control and a non-zero exit code if anything fails).
  - **Verification:** the check passes on the clean VM after running the script and fails if any control is altered.

---

## Technical Notes

- **Test environment:** clean VirtualBox VM with Ubuntu Server 24.04 LTS.
- **Script convention:** Bash with `set -euo pipefail`, idempotent, numbered by execution order (`NN_name.sh`) in `scripts/provision/`; each US also contributes its check in `scripts/provision/checks/`. No hardcoded values: parameters via documented environment variables.
- **Out of scope:** SSH (US-HOST-002), Docker installation (US-SYS-002), systemd unit (US-SYS-003), secrets management with a vault.
- **Lockout risk:** do not close the admin session until `sudo` has been verified with the new user.
