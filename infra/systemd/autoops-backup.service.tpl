# Managed by scripts/provision/70_systemd.sh. Triggered by autoops-backup.timer; manual: `sudo systemctl start autoops-backup`.
# No [Install] section: only the timer schedules it. A non-zero exit from the script leaves the unit `failed`.
[Unit]
Description=AutoOps PostgreSQL backup (pg_dump custom format)
Documentation=file:@@APP_DIR@@/infra/systemd/README.md
Requires=docker.service
# After= only: a backup must never start the stack (autoops.service) as a side effect.
After=docker.service autoops.service
AssertPathExists=@@APP_DIR@@/docker-compose.yml
AssertPathExists=@@APP_DIR@@/.env

[Service]
Type=oneshot
User=@@SERVICE_USER@@
WorkingDirectory=@@APP_DIR@@
Environment=APP_DIR=@@APP_DIR@@
Environment=DOCKER_CONFIG=@@APP_DIR@@/.docker
Environment=DOCKER_CLI_HINTS=false
# BACKUP_DIR and credentials are read by the script from .env (0600); nothing secret in the unit.
ExecStart=@@APP_DIR@@/scripts/ops/backup_postgres.sh
TimeoutStartSec=1800

NoNewPrivileges=yes
ProtectHome=yes
PrivateTmp=yes
ProtectSystem=full
ReadWritePaths=@@APP_DIR@@ @@BACKUP_DIR@@
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
