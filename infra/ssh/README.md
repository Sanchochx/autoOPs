# Acceso SSH de AutoOps

Configuración gestionada por `scripts/provision/20_ssh.sh` (verificación: `scripts/provision/checks/20_ssh.sh`).

| Archivo | Destino en el host |
|---|---|
| `10-autoops.conf.tpl` | `/etc/ssh/sshd_config.d/10-autoops.conf` |
| `autoops-deploy-entrypoint.sh` | `/usr/local/sbin/autoops-deploy-entrypoint` |
| `autoops-ssh-rollback.sh` | `/usr/local/sbin/autoops-ssh-rollback` |

## Variables

| Variable | Obligatoria | Descripción |
|---|---|---|
| `ADMIN_USER` | sí | Usuario administrador (creado por `10_users.sh`) |
| `ADMIN_SSH_PUBKEY_FILE` | sí | Ruta a la llave **pública** ed25519 del admin (una sola línea) |
| `DEPLOY_USER` | no (`autoops-deploy`) | Cuenta de CI/CD |
| `DEPLOY_SSH_PUBKEY_FILE` | no | Llave pública ed25519 de despliegue; si falta, no se crea la cuenta ni se permite su acceso |
| `DEPLOY_ALLOWED_FROM` | si hay llave de despliegue | Origen permitido (`from=`): IP o CIDR, separados por comas |
| `SSH_ROLLBACK_MINUTES` | no (`5`) | Ventana para confirmar antes del rollback automático |

## Aplicar sin quedarse fuera

1. Snapshot de la VM y una sesión SSH/consola ya abierta que **no se cierra**.
2. `sudo ADMIN_USER=… ADMIN_SSH_PUBKEY_FILE=… ./scripts/provision/20_ssh.sh`.
   Si la configuración cambia, se arma un rollback automático a los `SSH_ROLLBACK_MINUTES` minutos.
3. Desde **otra** terminal, abre una sesión nueva con la llave (`ssh -i <llave> <admin>@<host>`).
4. Si funciona: `sudo ADMIN_USER=… ./scripts/provision/20_ssh.sh --confirm` cancela el rollback.
   Si no funciona, no hagas nada: pasado el plazo el cambio se revierte solo. También puedes revertir ya con `sudo /usr/local/sbin/autoops-ssh-rollback`.

## Llave de despliegue (Fase 5)

- Se genera aparte de la del admin: `ssh-keygen -t ed25519 -f deploy_key -C autoops-deploy`.
- La **privada** vive solo como secreto de GitHub Actions; nunca en el repositorio ni en este host.
- La entrada en `authorized_keys` queda como `restrict,from="<CIDR>",command="/usr/local/sbin/autoops-deploy-entrypoint" <llave>`: sin PTY, sin forwarding y con un único comando permitido (`deploy`).
- La cuenta no está en `sudo` ni en `docker`. La acción real de despliegue se define en la Fase 5.

## Alta, rotación y revocación

- **Alta del admin:** añade la `.pub` a un archivo y vuelve a ejecutar el script (añade la llave a `authorized_keys` sin borrar las existentes).
- **Revocación del admin:** elimina la línea correspondiente de `/home/<admin>/.ssh/authorized_keys` (`sudo nano`). Efecto inmediato en nuevas conexiones; las sesiones abiertas siguen hasta cerrarse (termínalas con `sudo pkill -u <usuario> sshd` si es necesario).
- **Rotación:** genera la nueva llave, instálala, verifica el login con ella y entonces revoca la antigua. Nunca al revés.
- **Llave de despliegue:** `authorized_keys` de `DEPLOY_USER` se regenera por completo con cada ejecución; para rotar, cambia `DEPLOY_SSH_PUBKEY_FILE` y ejecuta de nuevo. Para revocar, borra el archivo `/home/<DEPLOY_USER>/.ssh/authorized_keys`.

## Recuperación de acceso

- **VirtualBox:** consola de la VM (login local con la contraseña del admin) y `sudo /usr/local/sbin/autoops-ssh-rollback`, o edita/borra `/etc/ssh/sshd_config.d/10-autoops.conf` y `sudo systemctl reload ssh`.
- **AWS EC2:** EC2 Serial Console o Session Manager, o montar el volumen en otra instancia y corregir `authorized_keys`.

## Notas

- El puerto se mantiene en 22: en Ubuntu 24.04 `ssh.socket` ignora `Port` de `sshd_config`.
- `PermitRootLogin no` y `AllowUsers` aplican a todas las cuentas; el rollback restaura el drop-in anterior, no el del sistema base.
