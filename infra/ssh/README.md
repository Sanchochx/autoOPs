# AutoOps SSH access

Configuration managed by `scripts/provision/20_ssh.sh` (verification: `scripts/provision/checks/20_ssh.sh`).

| File | Host destination |
|---|---|
| `10-autoops.conf.tpl` | `/etc/ssh/sshd_config.d/10-autoops.conf` |
| `autoops-deploy-entrypoint.sh` | `/usr/local/sbin/autoops-deploy-entrypoint` |
| `autoops-ssh-rollback.sh` | `/usr/local/sbin/autoops-ssh-rollback` |

## Variables

| Variable | Required | Description |
|---|---|---|
| `ADMIN_USER` | yes | Administrator user (created by `10_users.sh`) |
| `ADMIN_SSH_PUBKEY_FILE` | yes | Path to the admin's ed25519 **public** key (single line) |
| `DEPLOY_USER` | no (`autoops-deploy`) | CI/CD account |
| `DEPLOY_SSH_PUBKEY_FILE` | no | Deployment ed25519 public key; if missing, the account is not created and its access is not allowed |
| `DEPLOY_ALLOWED_FROM` | if a deploy key is set | Allowed origin (`from=`): IP or CIDR, comma-separated |
| `SSH_ROLLBACK_MINUTES` | no (`5`) | Window to confirm before the automatic rollback |

## Apply without locking yourself out

1. Snapshot the VM and keep an already-open SSH/console session that you **do not close**.
2. `sudo ADMIN_USER=… ADMIN_SSH_PUBKEY_FILE=… ./scripts/provision/20_ssh.sh`.
   If the configuration changes, an automatic rollback is armed for `SSH_ROLLBACK_MINUTES` minutes later.
3. From **another** terminal, open a new session with the key (`ssh -i <key> <admin>@<host>`).
4. If it works: `sudo ADMIN_USER=… ./scripts/provision/20_ssh.sh --confirm` cancels the rollback.
   If it does not, do nothing: after the deadline the change is reverted automatically. You can also revert right away with `sudo /usr/local/sbin/autoops-ssh-rollback`.

## Deploy key (Phase 5)

- Generate it separately from the admin's: `ssh-keygen -t ed25519 -f deploy_key -C autoops-deploy`.
- The **private** key lives only as a GitHub Actions secret; never in the repository nor on this host.
- The `authorized_keys` entry ends up as `restrict,from="<CIDR>",command="/usr/local/sbin/autoops-deploy-entrypoint" <key>`: no PTY, no forwarding and a single allowed command (`deploy`).
- The account is not in `sudo` nor `docker`. The actual deployment action is defined in Phase 5.

## Enrollment, rotation and revocation

- **Admin enrollment:** add the `.pub` to a file and run the script again (it adds the key to `authorized_keys` without removing existing ones).
- **Admin revocation:** remove the corresponding line from `/home/<admin>/.ssh/authorized_keys` (`sudo nano`). Immediate effect on new connections; open sessions persist until closed (terminate them with `sudo pkill -u <user> sshd` if needed).
- **Rotation:** generate the new key, install it, verify login with it, and only then revoke the old one. Never the other way around.
- **Deploy key:** `DEPLOY_USER`'s `authorized_keys` is fully regenerated on every run; to rotate, change `DEPLOY_SSH_PUBKEY_FILE` and run again. To revoke, delete the file `/home/<DEPLOY_USER>/.ssh/authorized_keys`.

## Access recovery

- **VirtualBox:** VM console (local login with the admin password) and `sudo /usr/local/sbin/autoops-ssh-rollback`, or edit/delete `/etc/ssh/sshd_config.d/10-autoops.conf` and `sudo systemctl reload ssh`.
- **AWS EC2:** EC2 Serial Console or Session Manager, or mount the volume on another instance and fix `authorized_keys`.

## Notes

- The port stays at 22: on Ubuntu 24.04 `ssh.socket` ignores `Port` from `sshd_config`.
- `PermitRootLogin no` and `AllowUsers` apply to all accounts; the rollback restores the previous drop-in, not the base system one.
