# Managed by scripts/provision/70_systemd.sh. Manual only: `sudo systemctl start autoops-migrate`.
# No [Install] section on purpose: it is never enabled at boot and autoops.service never runs it.
[Unit]
Description=AutoOps database migrations (Alembic upgrade head)
Documentation=file:@@APP_DIR@@/infra/systemd/README.md
Requires=docker.service
After=docker.service network-online.target autoops.service
AssertPathExists=@@APP_DIR@@/docker-compose.yml
AssertPathExists=@@APP_DIR@@/.env

[Service]
Type=oneshot
User=@@SERVICE_USER@@
WorkingDirectory=@@APP_DIR@@
Environment=DOCKER_CONFIG=@@APP_DIR@@/.docker
Environment=DOCKER_CLI_HINTS=false
# -T: no TTY under systemd. compose starts postgres (depends_on: service_healthy) if it is not up.
ExecStart=/usr/bin/docker compose --profile tools run --rm -T migrate
TimeoutStartSec=300

NoNewPrivileges=yes
ProtectHome=yes
PrivateTmp=yes
ProtectSystem=full
ReadWritePaths=@@APP_DIR@@
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ProtectClock=yes
ProtectHostname=yes
RestrictSUIDSGID=yes
RestrictRealtime=yes
RestrictNamespaces=yes
LockPersonality=yes
SystemCallArchitectures=native
CapabilityBoundingSet=
RestrictAddressFamilies=AF_UNIX
UMask=0077
