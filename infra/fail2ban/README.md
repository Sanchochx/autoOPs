# Protección contra fuerza bruta (fail2ban)

Gestionado por `scripts/provision/30_fail2ban.sh` (verificación: `scripts/provision/checks/30_fail2ban.sh`).

| Archivo | Destino en el host |
|---|---|
| `autoops.local.tpl` | `/etc/fail2ban/jail.d/autoops.local` |
| `fail2ban.local` | `/etc/fail2ban/fail2ban.local` (logs a syslog/journald) |

## Variables

| Variable | Obligatoria | Descripción |
|---|---|---|
| `FAIL2BAN_IGNOREIP` | sí | IP/CIDR que nunca se banean (admin y red local de la VM). El loopback se añade siempre |
| `FAIL2BAN_MAXRETRY` | no (`3`) | Intentos fallidos antes del ban |
| `FAIL2BAN_FINDTIME` | no (`10m`) | Ventana de conteo de intentos |
| `FAIL2BAN_BANTIME` | no (`1h`) | Duración del primer ban |
| `FAIL2BAN_BANTIME_FACTOR` | no (`2`) | Multiplicador por reincidencia |
| `FAIL2BAN_BANTIME_MAXTIME` | no (`1w`) | Tope del ban progresivo |
| `FAIL2BAN_BANACTION` | no | `ufw` si UFW está instalado; si no, `nftables` |
| `SSH_PORT` | no | Por defecto, el puerto efectivo de sshd |

## Compatibilidad con UFW (US-NET-001)

Con UFW instalado, el script usa `banaction = ufw`: los bans se insertan como reglas de UFW y no compiten con el firewall.
Si se aprovisiona fail2ban antes que UFW, se usa `nftables` y el script avisa; tras US-NET-001 basta con volver a ejecutarlo.

## Operación

- Estado: `sudo fail2ban-client status sshd`
- Desbanear: `sudo fail2ban-client set sshd unbanip <ip>`
- Logs: `journalctl -u fail2ban` (no hay archivos de log propios).
- Cuidado: un `ignoreip` incompleto puede dejarte fuera tras 3 fallos; incluye siempre tu IP de administración.
