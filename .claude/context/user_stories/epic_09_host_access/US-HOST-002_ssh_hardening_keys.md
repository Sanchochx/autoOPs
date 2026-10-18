# US-HOST-002: Hardening de SSH y Gestión de Llaves

**Épica:** 09 — Host Access & Identity
**Prioridad:** CRÍTICA
**Estimación:** 5 pts
**Dependencias:** US-HOST-001
**Estado:** Pendiente

---

## Historia de Usuario

**Como** administrador del servidor,
**necesito** que el acceso remoto sea exclusivamente por llaves criptográficas modernas y con superficie mínima,
**para** eliminar los ataques de contraseñas y poder otorgar y revocar accesos (humano y CI/CD) de forma controlada.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Autenticación Solo por Llave**
  - Instalar la llave pública `ed25519` del admin en `~/.ssh/authorized_keys` (permisos `700`/`600`) desde una variable/archivo, sin hardcodear la llave en el script.
  - Drop-in `/etc/ssh/sshd_config.d/10-autoops.conf` (plantilla versionada en `infra/ssh/`): `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `PermitRootLogin no`, `PubkeyAuthentication yes`.
  - **Verificación:** `sshd -t` valida; login por contraseña y como `root` rechazados; login con llave correcto.

- [ ] **CA-2: Superficie Reducida y Criptografía Moderna**
  - `AllowUsers` limitado al admin (y a la cuenta de despliegue del CA-3), `MaxAuthTries 3`, `LoginGraceTime 30`, `X11Forwarding no`, `AllowAgentForwarding no`, `AllowTcpForwarding no`, `ClientAliveInterval`/`ClientAliveCountMax`, banner de aviso.
  - Restringir algoritmos a los modernos (KEX, cifrados y MAC) compatibles con OpenSSH de Ubuntu 24.04.
  - **Verificación:** `sshd -T` refleja cada directiva; el script aplica el cambio con `sshd -t` previo y recarga sin cortar la sesión activa.

- [ ] **CA-3: Llave de Despliegue Dedicada para CI/CD**
  - Cuenta/llave separada de la del admin, para la Fase 5. La entrada en `authorized_keys` va restringida con `restrict`, `from="<CIDR>"` y `command="..."` hacia un script de despliegue acotado (sin shell interactiva). El CIDR de origen sale de variable de entorno.
  - Documentar que la llave privada vive solo como secreto de GitHub Actions y nunca en el repositorio.
  - **Verificación:** la llave de despliegue solo ejecuta el comando permitido; no obtiene shell, PTY ni forwarding.

- [ ] **CA-4: Rotación, Revocación y Verificación**
  - Documentar (README de `infra/ssh/`) el procedimiento de alta, rotación y revocación de llaves y la recuperación de acceso en la consola de la VM/EC2.
  - Check `scripts/provision/checks/20_ssh.sh` con `sshd -T` y permisos de `~/.ssh`.
  - **Verificación:** el check pasa; una llave retirada de `authorized_keys` deja de funcionar.

---

## Notas Técnicas

- **Riesgo de bloqueo:** mantener una segunda sesión abierta y probar el login en una conexión nueva antes de cerrar; conservar la consola de VirtualBox como vía de recuperación.
- **Fuera de alcance:** fail2ban (US-HOST-003), firewall (US-NET-001), certificados SSH / bastion, MFA para SSH.
- **Coherencia con el firewall:** el puerto SSH es configurable por variable; US-NET-001 debe leer el mismo valor.
