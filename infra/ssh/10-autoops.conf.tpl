# Managed by scripts/provision/20_ssh.sh. Do not edit by hand: regenerated.
# Name "10-": sshd uses the first value it reads, so this drop-in takes precedence
# over others in /etc/ssh/sshd_config.d (e.g. 50-cloud-init.conf with PasswordAuthentication yes).

# Key-only authentication
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
AuthenticationMethods publickey
PermitRootLogin no

# Reduced attack surface
AllowUsers @ALLOW_USERS@
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
Banner /etc/ssh/autoops-banner

# Modern cryptography (OpenSSH 9.6 on Ubuntu 24.04)
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
