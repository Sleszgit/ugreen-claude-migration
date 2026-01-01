#!/bin/bash
#
# Script 07: Firewall Configuration
# Part of Proxmox Security Hardening - Phase B
#
# Purpose: Configure Proxmox native firewall
# - Whitelist trusted desktop IP: 192.168.99.6
# - Lock down SSH (port 22 initially, will be 22022 after script 09)
# - Lock down Web UI (port 8006)
# - Default deny all other traffic
#

set -e  # Exit on error

SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"
BACKUP_DIR="$SCRIPT_DIR/backups"

# Trusted IPs
TRUSTED_DESKTOP="192.168.99.6"

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
echo "Phase B - Script 07: Firewall Configuration"
echo "=========================================="
echo ""

log "Starting firewall configuration"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo bash $0"
    exit 1
fi

echo "=== Current Firewall Status ==="
if systemctl is-active --quiet pve-firewall; then
    echo -e "${GREEN}pve-firewall service: ACTIVE${NC}"
else
    echo -e "${YELLOW}pve-firewall service: INACTIVE${NC}"
fi

if [ -f /etc/pve/firewall/cluster.fw ]; then
    echo "Existing cluster firewall config found"
    echo ""
    echo "Current configuration:"
    cat /etc/pve/firewall/cluster.fw
    echo ""
fi

# Backup existing firewall config
echo ""
echo "=== Backing Up Firewall Configuration ==="
mkdir -p "$BACKUP_DIR/firewall"
if [ -f /etc/pve/firewall/cluster.fw ]; then
    cp /etc/pve/firewall/cluster.fw "$BACKUP_DIR/firewall/cluster.fw.backup"
    log "Backed up: cluster.fw"
fi

# Display proposed firewall rules
echo ""
echo "=========================================="
echo "PROPOSED FIREWALL RULES"
echo "=========================================="
echo ""
cat <<'RULES'
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT
log_level_in: info

[RULES]
# Allow SSH from trusted desktop (current port 22, will be 22022 after SSH hardening)
IN ACCEPT -source 192.168.99.6 -p tcp -dport 22 -log nolog
IN ACCEPT -source 192.168.99.6 -p tcp -dport 22022 -log nolog

# Allow Proxmox Web UI from trusted desktop
IN ACCEPT -source 192.168.99.6 -p tcp -dport 8006 -log nolog

# Allow ICMP (ping) for network diagnostics
IN ACCEPT -p icmp -log nolog

# Allow localhost communication
IN ACCEPT -source 127.0.0.1 -log nolog
IN ACCEPT -source ::1 -log nolog

# Allow established and related connections
IN ACCEPT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -log nolog
IN ACCEPT -p udp -m conntrack --ctstate ESTABLISHED,RELATED -log nolog

# Drop everything else and log it
IN DROP -log warning
RULES

echo ""
echo "=========================================="
echo ""

echo -e "${YELLOW}IMPORTANT SAFETY INFORMATION:${NC}"
echo ""
echo "1. Trusted IP: $TRUSTED_DESKTOP (your desktop)"
echo "2. SSH will be allowed from: $TRUSTED_DESKTOP only"
echo "3. Web UI will be allowed from: $TRUSTED_DESKTOP only"
echo "4. All other traffic will be DROPPED"
echo "5. Your current SSH session will NOT be killed"
echo ""
echo -e "${RED}WARNING: If $TRUSTED_DESKTOP is incorrect, you will be locked out!${NC}"
echo ""

# Verify trusted IP
echo "=== Verifying Trusted IP ==="
echo "Your current SSH connection is from:"
CURRENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
if [ -z "$CURRENT_IP" ]; then
    CURRENT_IP=$(last -i | grep "still logged in" | head -1 | awk '{print $3}')
fi

echo "Detected IP: $CURRENT_IP"
echo "Trusted IP:  $TRUSTED_DESKTOP"
echo ""

if [ "$CURRENT_IP" != "$TRUSTED_DESKTOP" ]; then
    echo -e "${RED}WARNING: Your current IP ($CURRENT_IP) does NOT match trusted IP!${NC}"
    echo "This could be because:"
    echo "  1. You're connected from a different device"
    echo "  2. Your desktop IP changed"
    echo "  3. You're connected via proxy/VPN"
    echo ""
fi

read -p "Is $TRUSTED_DESKTOP correct? Type 'yes' to continue: " CONFIRM_IP
if [ "$CONFIRM_IP" != "yes" ]; then
    echo "Aborting. Please update TRUSTED_DESKTOP in the script."
    exit 1
fi

# Create firewall configuration
echo ""
echo "=== Creating Firewall Configuration ==="

mkdir -p /etc/pve/firewall

cat > /etc/pve/firewall/cluster.fw <<EOF
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT
log_level_in: info

[RULES]
# Allow SSH from trusted desktop (ports 22 and 22022 for transition period)
IN ACCEPT -source $TRUSTED_DESKTOP -p tcp -dport 22 -log nolog
IN ACCEPT -source $TRUSTED_DESKTOP -p tcp -dport 22022 -log nolog

# Allow Proxmox Web UI from trusted desktop
IN ACCEPT -source $TRUSTED_DESKTOP -p tcp -dport 8006 -log nolog

# Allow ICMP (ping) for network diagnostics
IN ACCEPT -p icmp -log nolog

# Allow localhost communication
IN ACCEPT -source 127.0.0.1 -log nolog
IN ACCEPT -source ::1 -log nolog

# Allow established and related connections
IN ACCEPT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -log nolog
IN ACCEPT -p udp -m conntrack --ctstate ESTABLISHED,RELATED -log nolog

# Drop everything else and log it
IN DROP -log warning
EOF

log "Created: /etc/pve/firewall/cluster.fw"

# Display created configuration
echo ""
echo "Configuration created:"
cat /etc/pve/firewall/cluster.fw
echo ""

# Enable and restart firewall
echo ""
echo "=== Enabling Proxmox Firewall ==="
read -p "Enable firewall now? Type 'yes' to continue: " ENABLE_FW
if [ "$ENABLE_FW" != "yes" ]; then
    echo "Firewall NOT enabled. Configuration saved but inactive."
    echo ""
    echo "To enable manually later:"
    echo "  systemctl enable pve-firewall"
    echo "  systemctl restart pve-firewall"
    exit 0
fi

systemctl enable pve-firewall
systemctl restart pve-firewall
log "Firewall enabled and restarted"

# Wait for firewall to apply
sleep 2

# Check firewall status
echo ""
echo "=== Firewall Status ==="
systemctl status pve-firewall --no-pager | head -15

echo ""
echo "=== Active Firewall Rules ==="
iptables -L -n -v | head -40

echo ""
echo "=========================================="
echo -e "${GREEN}Script 07 Completed Successfully!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Firewall configured: YES"
echo "  - Firewall enabled: YES"
echo "  - Trusted IP: $TRUSTED_DESKTOP"
echo "  - Allowed ports: 22, 22022, 8006"
echo "  - Default policy: DROP"
echo ""
echo "Emergency Disable (if locked out via console):"
echo "  systemctl stop pve-firewall"
echo ""
echo "Next steps:"
echo "  1. Test connectivity from $TRUSTED_DESKTOP"
echo "  2. Run Script 08: Proxmox Backup (optional)"
echo "  3. Run Script 09: SSH Hardening"
echo ""
log "Script 07 completed successfully"
