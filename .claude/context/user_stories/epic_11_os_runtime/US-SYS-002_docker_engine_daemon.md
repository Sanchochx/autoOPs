# US-SYS-002: Docker Engine on the Host and Hardened `daemon.json`

**Epic:** 11 — OS Hardening & Runtime
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** US-SYS-001
**Status:** Completed

---

## User Story

**As** the server administrator,
**I need** to install Docker Engine from the official repository with a secure-by-default daemon configuration,
**so that** I can run the AutoOps stack with log rotation, reasonable limits and no privilege escalation.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is done and pause at the final checkpoint before closing the US.

- [x] **AC-1: Installation from the Official Repository**
  - Idempotent script `scripts/provision/60_docker.sh`: Docker's official apt repository with its GPG key verified, installation of `docker-ce`, `docker-ce-cli`, `containerd.io` and the `buildx` and `compose` plugins; versions pinnable via variable.
  - **Verification:** `docker version` and `docker compose version` work; re-running the script changes nothing.

- [x] **AC-2: Hardened `daemon.json`**
  - Template `infra/docker/daemon.json`: `"no-new-privileges": true`, `"log-driver": "json-file"` with `max-size`/`max-file`, `"live-restore": true`, `"userland-proxy": false`. Without disabling `iptables`.
  - **Verification:** `docker info` reflects the configuration; the Compose stack starts and its containers respect `no-new-privileges`.

- [x] **AC-3: Socket Access and Group Membership**
  - No users in the `docker` group except `autoops` (see US-HOST-001 AC-4); `/var/run/docker.sock` socket with default permissions and no TCP exposure of the daemon.
  - **Verification:** `ss -tlnp` does not show port 2375/2376; the admin uses `sudo docker`.

- [x] **AC-4: Documented Decision and Verification**
  - Record in `infra/docker/README.md` why standard Docker is used and not *rootless* (Phase 5 proxy ports <1024 and `internal` networks), and that `userns-remap` remains a future improvement.
  - Check `scripts/provision/checks/60_docker.sh`.
  - **Verification:** the check passes and `docker compose up -d --build` leaves all services `healthy`.

---

## Technical Notes

- **Cloud-native logging:** containers keep emitting to stdout/stderr; the driver's rotation prevents logs from filling the disk.
- **Out of scope:** rootless Docker, private image registry, image scanning.
