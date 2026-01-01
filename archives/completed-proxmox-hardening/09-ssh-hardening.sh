#!/bin/bash
#
# Script 09: SSH Hardening
# Part of Proxmox Security Hardening - Phase B
#
# Purpose: Harden SSH configuration
# - Change SSH port from 22 to 22022
# - Disable root password login (keep root key login)
# - Disable ALL password authentication (keys only)
# - Additional security hardening
#
# CRITICAL: SSH key authentication MUST be working before running this!
#

set -e  # Exit on error

SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"
BACKUP_DIR="$SCRIPT_DIR/backups"

NEW_SSH_PORT="22022"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

echo "=========================================="
echo "Phase B - Script 09: SSH Hardening"
echo "=========================================="
echo ""
echo -e "${RED}CRITICAL WARNING!${NC}"
echo ""
echo "This script will:"
echo "  1. Change SSH port from 22 to $NEW_SSH_PORT"
echo "  2. Disable password authentication (SSH keys ONLY)"
echo "  3. Disable root password login via SSH"
echo ""
echo -e "${YELLOW}REQUIREMENTS:${NC}"
echo "  - SSH key authentication MUST be working"
echo "  - You MUST have tested SSH key login"
echo "  - You MUST keep multiple SSH sessions open"
echo "  - You MUST have emergency access (Web UI Shell or console)"
echo ""
echo -e "${RED}If SSH keys are not working, you WILL be locked out!${NC}"
echo ""

log "Starting SSH hardening"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo bash $0"
    exit 1
fi

# Pre-flight checks
echo "=== Pre-Flight Safety Checks ==="
echo ""

# Check 1: Verify SSH key authentication files exist
echo "Check 1: SSH Key Files"
if [ -f /root/.ssh/authorized_keys ]; then
    echo -e "${GREEN}✓ Root authorized_keys exists${NC}"
    ROOT_KEYS=$(wc -l < /root/.ssh/authorized_keys)
    echo "  Keys configured: $ROOT_KEYS"
else
    echo -e "${RED}✗ Root authorized_keys NOT FOUND!${NC}"
    echo "  SSH key authentication NOT configured for root!"
    echo "  ABORTING - Configure SSH keys first (Script 04)"
    exit 1
fi

if [ -f /home/sleszugreen/.ssh/authorized_keys ]; then
    echo -e "${GREEN}✓ sleszugreen authorized_keys exists${NC}"
    USER_KEYS=$(wc -l < /home/sleszugreen/.ssh/authorized_keys)
    echo "  Keys configured: $USER_KEYS"
else
    echo -e "${RED}✗ sleszugreen authorized_keys NOT FOUND!${NC}"
    echo "  ABORTING - Configure SSH keys first"
    exit 1
fi

# Check 2: Verify Web UI is accessible (emergency access)
echo ""
echo "Check 2: Emergency Access"
if systemctl is-active --quiet pveproxy; then
    echo -e "${GREEN}✓ Web UI (pveproxy) is running${NC}"
    echo "  Emergency access: https://192.168.40.60:8006"
else
    echo -e "${RED}✗ Web UI is NOT running!${NC}"
    echo "  WARNING: No emergency access available!"
    read -p "Continue anyway? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        exit 1
    fi
fi

# Check 3: Verify we're in an SSH session
echo ""
echo "Check 3: Current Session"
if [ -n "$SSH_CONNECTION" ]; then
    echo -e "${GREEN}✓ Running in SSH session${NC}"
    echo "  Connection: $SSH_CONNECTION"
else
    echo -e "${YELLOW}⚠ Not running in SSH session${NC}"
    echo "  (Running from console or Web UI Shell)"
fi

# Check 4: Count active SSH sessions
ACTIVE_SESSIONS=$(who | grep -c pts || echo "0")
echo ""
echo "Check 4: Active SSH Sessions"
echo "  Active sessions: $ACTIVE_SESSIONS"
if [ "$ACTIVE_SESSIONS" -lt 2 ]; then
    echo -e "${YELLOW}⚠ WARNING: Less than 2 SSH sessions detected${NC}"
    echo "  It's recommended to have 2+ sessions open for safety"
fi

# Final confirmation
echo ""
echo "=========================================="
echo -e "${RED}FINAL CONFIRMATION${NC}"
echo "=========================================="
echo ""
echo "Have you:"
echo "  [  ] Tested SSH key authentication for root?"
echo "  [  ] Tested SSH key authentication for sleszugreen?"
echo "  [  ] Opened 2+ SSH sessions?"
echo "  [  ] Verified Web UI access works?"
echo "  [  ] Written down emergency access methods?"
echo ""
read -p "Type 'I HAVE TESTED SSH KEYS' to continue: " CONFIRM

if [ "$CONFIRM" != "I HAVE TESTED SSH KEYS" ]; then
    echo "Aborting. Test SSH keys first!"
    echo ""
    echo "Test with:"
    echo "  ssh -i C:\\Users\\jakub\\.ssh\\ugreen_key root@192.168.40.60"
    echo "  ssh -i C:\\Users\\jakub\\.ssh\\ugreen_key sleszugreen@192.168.40.60"
    exit 1
fi

# Backup current SSH config
echo ""
echo "=== Backing Up SSH Configuration ==="
mkdir -p "$BACKUP_DIR/ssh"
cp /etc/ssh/sshd_config "$BACKUP_DIR/ssh/sshd_config.before-hardening"
log "Backed up: sshd_config"

# Display current SSH config
echo ""
echo "=== Current SSH Configuration ==="
grep -E "^Port |^PermitRootLogin |^PasswordAuthentication |^PubkeyAuthentication " /etc/ssh/sshd_config || echo "(Using defaults)"

# Create new hardened SSH configuration
echo ""
echo "=== Creating Hardened SSH Configuration ==="

# Read current config and modify
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.new

# Change/add SSH port
if grep -q "^Port " /etc/ssh/sshd_config; then
    sed -i "s/^Port .*/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config.new
else
    echo "Port $NEW_SSH_PORT" >> /etc/ssh/sshd_config.new
fi

# Disable root password login (but keep root KEY login)
if grep -q "^PermitRootLogin " /etc/ssh/sshd_config; then
    sed -i "s/^PermitRootLogin .*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config.new
else
    echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config.new
fi

# Ensure public key authentication is enabled
if grep -q "^PubkeyAuthentication " /etc/ssh/sshd_config; then
    sed -i "s/^PubkeyAuthentication .*/PubkeyAuthentication yes/" /etc/ssh/sshd_config.new
else
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config.new
fi

# Disable password authentication completely
if grep -q "^PasswordAuthentication " /etc/ssh/sshd_config; then
    sed -i "s/^PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config.new
else
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config.new
fi

# Disable challenge-response authentication
if grep -q "^ChallengeResponseAuthentication " /etc/ssh/sshd_config; then
    sed -i "s/^ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config.new
else
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config.new
fi

# Additional hardening options
cat >> /etc/ssh/sshd_config.new <<EOF

# Additional SSH Hardening (added by script 09)
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 60
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowAgentForwarding yes
AllowTcpForwarding yes
PermitEmptyPasswords no
PermitUserEnvironment no
EOF

# Test new SSH configuration
echo ""
echo "=== Testing New SSH Configuration ==="
if sshd -t -f /etc/ssh/sshd_config.new; then
    echo -e "${GREEN}✓ SSH configuration syntax is valid${NC}"
else
    echo -e "${RED}✗ SSH configuration has ERRORS!${NC}"
    echo "Aborting - will not apply broken config"
    exit 1
fi

# Show what will change
echo ""
echo "=== Configuration Changes ==="
echo ""
echo "SSH Port: 22 → $NEW_SSH_PORT"
echo "Password Authentication: DISABLED (keys only)"
echo "Root Login: Password disabled, keys allowed"
echo ""

# Apply new configuration
read -p "Apply new SSH configuration? (yes/no): " APPLY
if [ "$APPLY" != "yes" ]; then
    echo "Configuration NOT applied."
    rm /etc/ssh/sshd_config.new
    exit 0
fi

mv /etc/ssh/sshd_config.new /etc/ssh/sshd_config
log "Applied new SSH configuration"

# Display new config
echo ""
echo "=== New SSH Configuration ==="
grep -E "^Port |^PermitRootLogin |^PasswordAuthentication |^PubkeyAuthentication |^MaxAuthTries |^ClientAliveInterval " /etc/ssh/sshd_config

# Restart SSH service
echo ""
echo "=== Restarting SSH Service ==="
echo -e "${YELLOW}Your current SSH session will NOT be killed${NC}"
echo "The new configuration will apply to NEW connections"
echo ""
read -p "Restart SSH now? (yes/no): " RESTART
if [ "$RESTART" != "yes" ]; then
    echo "SSH NOT restarted. Configuration will NOT take effect until restart."
    echo "To restart manually: systemctl restart ssh"
    exit 0
fi

systemctl restart ssh
log "SSH service restarted"

# Verify SSH is running
sleep 2
if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}✓ SSH service is running${NC}"
else
    echo -e "${RED}✗ SSH service FAILED to start!${NC}"
    echo "EMERGENCY: Restoring backup config..."
    cp "$BACKUP_DIR/ssh/sshd_config.before-hardening" /etc/ssh/sshd_config
    systemctl restart ssh
    echo "Original configuration restored"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Script 09 Completed Successfully!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - SSH port changed: 22 → $NEW_SSH_PORT"
echo "  - Password authentication: DISABLED"
echo "  - Root password login: DISABLED"
echo "  - Root key login: ENABLED"
echo "  - Public key authentication: ENABLED"
echo ""
echo -e "${YELLOW}CRITICAL NEXT STEPS:${NC}"
echo ""
echo "1. DO NOT CLOSE THIS SESSION!"
echo ""
echo "2. Test new SSH connection in a NEW terminal:"
echo "   ssh -i C:\\Users\\jakub\\.ssh\\ugreen_key -p $NEW_SSH_PORT root@192.168.40.60"
echo ""
echo "3. If new connection works:"
echo "   - Update firewall to remove port 22 (optional)"
echo "   - Update desktop SSH config for new port"
echo "   - Run Script 10: Checkpoint #2"
echo ""
echo "4. If new connection FAILS:"
echo "   - DO NOT CLOSE THIS SESSION!"
echo "   - Restore config: cp $BACKUP_DIR/ssh/sshd_config.before-hardening /etc/ssh/sshd_config"
echo "   - Restart SSH: systemctl restart ssh"
echo ""
echo "Emergency restore command:"
echo "  cp $BACKUP_DIR/ssh/sshd_config.before-hardening /etc/ssh/sshd_config && systemctl restart ssh"
echo ""
log "Script 09 completed - SSH now hardened on port $NEW_SSH_PORT"
