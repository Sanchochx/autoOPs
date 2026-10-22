# Managed by scripts/provision/30_fail2ban.sh (US-HOST-003). Do not edit by hand:
# regenerated on every run. See infra/fail2ban/README.md.
[sshd]
enabled  = true
port     = @SSH_PORT@
# Reads journald: no log files. _COMM is a trusted field (set by journald),
# and covers both sshd and sshd-session (OpenSSH >= 9.8) without depending on the unit name.
backend     = systemd
journalmatch = _COMM=sshd + _COMM=sshd-session
filter   = sshd
maxretry = @MAXRETRY@
findtime = @FINDTIME@
bantime  = @BANTIME@
# Progressive ban: each repeat offense multiplies the ban time (up to bantime.maxtime).
bantime.increment = true
bantime.factor    = @BANTIME_FACTOR@
bantime.maxtime   = @BANTIME_MAXTIME@
ignoreip = @IGNOREIP@
banaction = @BANACTION@
banaction_allports = @BANACTION@
