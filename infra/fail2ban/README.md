# Brute-force protection (fail2ban)

Managed by `scripts/provision/30_fail2ban.sh` (verification: `scripts/provision/checks/30_fail2ban.sh`).

| File | Host destination |
|---|---|
| `autoops.local.tpl` | `/etc/fail2ban/jail.d/autoops.local` |
| `fail2ban.local` | `/etc/fail2ban/fail2ban.local` (logs to syslog/journald) |

## Variables

| Variable | Required | Description |
|---|---|---|
| `FAIL2BAN_IGNOREIP` | yes | IPs/CIDRs that are never banned (admin and the VM's local network). Loopback is always added |
| `FAIL2BAN_MAXRETRY` | no (`3`) | Failed attempts before a ban |
| `FAIL2BAN_FINDTIME` | no (`10m`) | Attempt counting window |
| `FAIL2BAN_BANTIME` | no (`1h`) | Duration of the first ban |
| `FAIL2BAN_BANTIME_FACTOR` | no (`2`) | Multiplier per repeat offense |
| `FAIL2BAN_BANTIME_MAXTIME` | no (`1w`) | Cap for the progressive ban |
| `FAIL2BAN_BANACTION` | no | `ufw` if UFW is installed; otherwise `nftables` |
| `SSH_PORT` | no | Defaults to sshd's effective port |

## UFW compatibility (US-NET-001)

With UFW installed, the script uses `banaction = ufw`: bans are inserted as UFW rules and do not compete with the firewall.
If fail2ban is provisioned before UFW, `nftables` is used and the script warns; after US-NET-001 it is enough to run it again.

## Operation

- Status: `sudo fail2ban-client status sshd`
- Unban: `sudo fail2ban-client set sshd unbanip <ip>`
- Logs: `journalctl -u fail2ban` (there are no log files of its own).
- Caution: an incomplete `ignoreip` can lock you out after 3 failures; always include your administration IP.
