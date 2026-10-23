# Managed by scripts/provision/70_systemd.sh. @@BACKUP_SCHEDULE@@ is rendered from BACKUP_SCHEDULE in .env
# (systemd cannot expand environment variables in OnCalendar=). Re-run the script after changing it.
[Unit]
Description=AutoOps PostgreSQL backup schedule
Documentation=file:@@APP_DIR@@/infra/systemd/README.md

[Timer]
OnCalendar=@@BACKUP_SCHEDULE@@
# Spreads the start to avoid fixed-time load spikes.
RandomizedDelaySec=15min
# Runs a missed backup at the next boot if the host was off at the scheduled time.
Persistent=true
Unit=autoops-backup.service

[Install]
WantedBy=timers.target
