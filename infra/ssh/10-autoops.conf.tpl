# Gestionado por scripts/provision/20_ssh.sh. No editar a mano: se regenera.
# Nombre "10-": sshd usa el primer valor que lee, así que este drop-in se impone
# a otros de /etc/ssh/sshd_config.d (p. ej. 50-cloud-init.conf con PasswordAuthentication yes).

# Autenticación solo por llave
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
AuthenticationMethods publickey
PermitRootLogin no

# Superficie reducida
AllowUsers @ALLOW_USERS@
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
Banner /etc/ssh/autoops-banner

# Criptografía moderna (OpenSSH 9.6 de Ubuntu 24.04)
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
