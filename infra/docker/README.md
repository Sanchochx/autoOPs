# Docker Engine on the host

Managed by `scripts/provision/60_docker.sh` (verification: `scripts/provision/checks/60_docker.sh`).

| File | Host destination |
|---|---|
| `daemon.json` | `/etc/docker/daemon.json` |

The script also creates `/etc/apt/keyrings/docker.asc` and `/etc/apt/sources.list.d/docker.sources` (official repository, `Signed-By`).

## Variables (all optional)

| Variable | Description |
|---|---|
| `DOCKER_VERSION` | apt version of `docker-ce` and `docker-ce-cli`; empty = latest in the repository |
| `DOCKER_CONTAINERD_VERSION`, `DOCKER_COMPOSE_VERSION`, `DOCKER_BUILDX_VERSION` | Same for each package |
| `DOCKER_APT_SUITE` | Repository suite (defaults to `VERSION_CODENAME`); useful if Docker has not yet published your release |
| `DOCKER_GPG_FINGERPRINT` | Expected key fingerprint (defaults to Docker's official one) |
| `SERVICE_USER` | Sole member of the `docker` group (`autoops`) |

Available versions: `apt-cache madison docker-ce`. Without a pinned version, `apt-get upgrade` (50_os_baseline.sh) may upgrade Docker; with `live-restore`, containers survive a daemon restart.

## `daemon.json`

| Key | Reason |
|---|---|
| `no-new-privileges: true` | Container processes cannot gain privileges via setuid |
| `log-driver: json-file` + `max-size 10m` / `max-file 3` | Containers keep emitting to stdout/stderr; rotation prevents filling the disk |
| `live-restore: true` | Restarting or upgrading the daemon does not stop containers |
| `userland-proxy: false` | Published ports use iptables rules instead of the `docker-proxy` process |

`"iptables": false` is **not** set (it would break container Internet egress and the compose `internal` networks), nor is `"hosts"` (the daemon is not exposed over TCP). Filtering published ports against UFW is handled in US-NET-002 with the `DOCKER-USER` chain.

## Decision: standard Docker, not rootless

- The Phase 5 reverse proxy needs to bind ports 80/443 (<1024), which complicates rootless mode.
- The `internal` networks and the compose network model rely on daemon-managed iptables, which rootless does not provide equivalently.
- Mitigations adopted: `no-new-privileges`, restricted `docker` group, no TCP exposure, non-root containers (Phase 3 Dockerfiles).
- `userns-remap` remains a future improvement (it changes volume ownership and requires testing the full stack).

## Access

- Membership in the `docker` group is equivalent to being `root`. Only `autoops` (run by systemd, US-SYS-003) is in the group; the script removes everyone else. The admin uses `sudo docker`.
- The `/var/run/docker.sock` socket keeps `root:docker 660`.

## Verify the stack (AC-4)

```bash
cd /opt/autoops    # or the repository directory
sudo docker compose up -d --build
sudo docker compose ps          # all services must end up healthy
```
