# US-HOST-002: SSH Hardening and Key Management

**Epic:** 09 — Host Access & Identity
**Priority:** CRITICAL
**Estimate:** 5 pts
**Dependencies:** US-HOST-001
**Status:** Completed

---

## User Story

**As** the server administrator,
**I need** remote access to be exclusively via modern cryptographic keys and with a minimal surface,
**so that** password attacks are eliminated and access (human and CI/CD) can be granted and revoked in a controlled way.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is done and pause at the final checkpoint before closing the US.

- [x] **AC-1: Key-Only Authentication**
  - Install the admin's `ed25519` public key in `~/.ssh/authorized_keys` (permissions `700`/`600`) from a variable/file, without hardcoding the key in the script.
  - Drop-in `/etc/ssh/sshd_config.d/10-autoops.conf` (versioned template in `infra/ssh/`): `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `PermitRootLogin no`, `PubkeyAuthentication yes`.
  - **Verification:** `sshd -t` validates; password login and login as `root` are rejected; key login works.

- [x] **AC-2: Reduced Surface and Modern Cryptography**
  - `AllowUsers` limited to the admin (and to the deployment account from AC-3), `MaxAuthTries 3`, `LoginGraceTime 30`, `X11Forwarding no`, `AllowAgentForwarding no`, `AllowTcpForwarding no`, `ClientAliveInterval`/`ClientAliveCountMax`, warning banner.
  - Restrict algorithms to modern ones (KEX, ciphers and MACs) compatible with Ubuntu 24.04's OpenSSH.
  - **Verification:** `sshd -T` reflects each directive; the script applies the change with a prior `sshd -t` and reloads without cutting the active session.

- [x] **AC-3: Dedicated Deployment Key for CI/CD**
  - Account/key separate from the admin's, for Phase 5. The `authorized_keys` entry is restricted with `restrict`, `from="<CIDR>"` and `command="..."` pointing to a bounded deployment script (no interactive shell). The source CIDR comes from an environment variable.
  - Document that the private key lives only as a GitHub Actions secret and never in the repository.
  - **Verification:** the deployment key only runs the allowed command; it gets no shell, PTY or forwarding.

- [x] **AC-4: Rotation, Revocation and Verification**
  - Document (README in `infra/ssh/`) the procedure for adding, rotating and revoking keys and for recovering access through the VM/EC2 console.
  - Check `scripts/provision/checks/20_ssh.sh` with `sshd -T` and `~/.ssh` permissions.
  - **Verification:** the check passes; a key removed from `authorized_keys` stops working.

---

## Technical Notes

- **Lockout risk:** keep a second session open and test login on a new connection before closing; keep the VirtualBox console as a recovery path.
- **Out of scope:** fail2ban (US-HOST-003), firewall (US-NET-001), SSH certificates / bastion, MFA for SSH.
- **SSH port:** stays at 22. On Ubuntu 24.04 `ssh.socket` ignores `Port` from `sshd_config`; changing it requires a socket override and is out of scope. US-HOST-003 and US-NET-001 read the effective port (`sshd -T`).
- **Anti-lockout:** if the configuration changes, the script arms an automatic rollback (transient systemd timer) that is only cancelled with `20_ssh.sh --confirm` after testing key login in a new session.
