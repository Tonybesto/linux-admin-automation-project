#!/bin/bash

# Enhanced System Hardening Script
# Hardens SSH, disables unnecessary services, updates system, configures firewall, and sets kernel + system policies

SSH_PORT=22  # Change to preferred SSH port
LOG_FILE="/var/log/system_hardening.log"
UNWANTED_SERVICES=("ftp" "telnet" "rsh" "rlogin" "rexec" "nfs" "vnc" "snmp" "squid" "smb" "nmb" "ypserv" "ypbind" "tftp" "chargen" "daytime" "discard" "echo" "time" "talk" "ntalk" "sendmail" "identd" "rpcbind" "xinetd")

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root." >&2
    exit 1
fi

# Logger
log() {
    local MSG="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$MSG" | tee -a "$LOG_FILE"
    logger -t system_hardening "$1"
}

# Backup file
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$1.bak-$(date +%Y%m%d)"
        log "Backup created for $1"
    fi
}

# Update packages
update_system() {
    log "Updating system..."
    if command -v apt-get &>/dev/null; then
        apt-get update && apt-get upgrade -y
        apt-get autoremove -y && apt-get autoclean
    elif command -v yum &>/dev/null; then
        yum update -y && yum autoremove -y
    elif command -v dnf &>/dev/null; then
        dnf upgrade -y && dnf autoremove -y
    else
        log "No known package manager found."
        return 1
    fi
    log "System updated."
}

# Harden SSH
secure_ssh() {
    log "Securing SSH..."
    SSH_CONFIG="/etc/ssh/sshd_config"
    backup_file "$SSH_CONFIG"

    sed -i "s/^#\?Port .*/Port $SSH_PORT/" "$SSH_CONFIG"
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSH_CONFIG"
    sed -i 's/^#\?UsePAM.*/UsePAM yes/' "$SSH_CONFIG"
    sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' "$SSH_CONFIG"
    sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 2/' "$SSH_CONFIG"
    sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"
    sed -i 's/^#\?LoginGraceTime.*/LoginGraceTime 60/' "$SSH_CONFIG"
    sed -i 's/^#\?AllowAgentForwarding.*/AllowAgentForwarding no/' "$SSH_CONFIG"
    sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding no/' "$SSH_CONFIG"
    sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSH*
