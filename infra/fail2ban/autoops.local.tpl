# Gestionado por scripts/provision/30_fail2ban.sh (US-HOST-003). No editar a mano:
# se regenera en cada ejecución. Ver infra/fail2ban/README.md.
[sshd]
enabled  = true
port     = @SSH_PORT@
# Lee journald: sin archivos de log. _COMM es un campo confiable (lo fija journald),
# y cubre tanto sshd como sshd-session (OpenSSH >= 9.8) sin depender del nombre de la unidad.
backend     = systemd
journalmatch = _COMM=sshd + _COMM=sshd-session
filter   = sshd
maxretry = @MAXRETRY@
findtime = @FINDTIME@
bantime  = @BANTIME@
# Ban progresivo: cada reincidencia multiplica el tiempo de ban (hasta bantime.maxtime).
bantime.increment = true
bantime.factor    = @BANTIME_FACTOR@
bantime.maxtime   = @BANTIME_MAXTIME@
ignoreip = @IGNOREIP@
banaction = @BANACTION@
banaction_allports = @BANACTION@
