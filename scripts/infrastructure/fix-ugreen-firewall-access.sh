#!/usr/bin/env bash
# =============================================================================
# Fix UGREEN Proxmox Firewall - Enable LXC102 and Homelab Access
# =============================================================================
# Purpose: Add firewall rules to allow LXC102 and Homelab to access UGREEN
# Run on: UGREEN Proxmox HOST (NOT in container)
# Path on host: /nvme2tb/lxc102scripts/fix-ugreen-firewall-access.sh
# Usage: sudo bash /nvme2tb/lxc102scripts/fix-ugreen-firewall-access.sh
# =============================================================================

set -Euo pipefail
trap 'echo "ERROR on line $LINENO, exit code $?"' ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') | $*"
}

error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $*"
}

warn() {
    echo -e "${YELLOW}WARNING:${NC} $*"
}

# =============================================================================
# PREFLIGHT CHECKS
# =============================================================================

log "Starting UGREEN Proxmox firewall fix..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
    echo "Usage: sudo bash $0"
    exit 1
fi

# Check if running on Proxmox
if ! command -v pveversion &>/dev/null; then
    error "This script must be run on a Proxmox host"
    echo "Current hostname: $(hostname)"
    exit 1
fi

# Verify we're on UGREEN (not homelab)
CURRENT_IP=$(hostname -I | awk '{print $1}')
log "Current host IP: $CURRENT_IP"

if [[ "$CURRENT_IP" != "192.168.40.60" ]]; then
    warn "Expected IP 192.168.40.60 (UGREEN), got $CURRENT_IP"
    read -p "Continue anyway? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log "Aborted by user"
        exit 0
    fi
fi

# =============================================================================
# CONFIGURATION
# =============================================================================

CLUSTER_FW="/etc/pve/firewall/cluster.fw"
BACKUP_FILE="/etc/pve/firewall/cluster.fw.backup.$(date +%Y%m%d_%H%M%S)"

# Rules to add
RULES_TO_ADD=(
    "# === LXC102 and Homelab Access Rules (added $(date +%Y-%m-%d)) ==="
    "# Allow API access from LXC102 (192.168.40.82)"
    "IN ACCEPT -source 192.168.40.82 -p tcp -dport 8006 -log nolog"
    "# Allow SSH access from LXC102"
    "IN ACCEPT -source 192.168.40.82 -p tcp -dport 22 -log nolog"
    "# Allow API access from Homelab (192.168.40.40)"
    "IN ACCEPT -source 192.168.40.40 -p tcp -dport 8006 -log nolog"
    "# Allow SSH access from Homelab"
    "IN ACCEPT -source 192.168.40.40 -p tcp -dport 22 -log nolog"
)

# =============================================================================
# BACKUP EXISTING CONFIG
# =============================================================================

log "Backing up current firewall config..."

if [ -f "$CLUSTER_FW" ]; then
    cp "$CLUSTER_FW" "$BACKUP_FILE"
    success "Backup saved to: $BACKUP_FILE"
    echo ""
    log "Current firewall rules:"
    echo "----------------------------------------"
    cat "$CLUSTER_FW"
    echo "----------------------------------------"
    echo ""
else
    warn "No existing cluster.fw file found, will create new one"
    # Create directory if needed
    mkdir -p "$(dirname "$CLUSTER_FW")"
fi

# =============================================================================
# CHECK IF RULES ALREADY EXIST
# =============================================================================

log "Checking for existing rules..."

RULES_NEEDED=0
for rule in "192.168.40.82.*8006" "192.168.40.82.*22" "192.168.40.40.*8006" "192.168.40.40.*22"; do
    if ! grep -qE "$rule" "$CLUSTER_FW" 2>/dev/null; then
        RULES_NEEDED=1
        break
    fi
done

if [ "$RULES_NEEDED" -eq 0 ]; then
    success "All required rules already exist in firewall config"
    log "No changes needed"
    exit 0
fi

# =============================================================================
# ADD FIREWALL RULES
# =============================================================================

log "Adding firewall rules..."

# Append rules to cluster.fw
{
    echo ""
    for rule in "${RULES_TO_ADD[@]}"; do
        echo "$rule"
    done
} >> "$CLUSTER_FW"

success "Rules added to $CLUSTER_FW"

echo ""
log "Updated firewall rules:"
echo "----------------------------------------"
cat "$CLUSTER_FW"
echo "----------------------------------------"
echo ""

# =============================================================================
# APPLY IPTABLES RULES IMMEDIATELY
# =============================================================================

log "Applying iptables rules immediately..."

# Add immediate iptables rules (don't wait for firewall restart)
iptables -I INPUT 1 -s 192.168.40.82 -p tcp --dport 8006 -j ACCEPT 2>/dev/null || true
iptables -I INPUT 1 -s 192.168.40.82 -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
iptables -I INPUT 1 -s 192.168.40.40 -p tcp --dport 8006 -j ACCEPT 2>/dev/null || true
iptables -I INPUT 1 -s 192.168.40.40 -p tcp --dport 22 -j ACCEPT 2>/dev/null || true

success "Immediate iptables rules applied"

# =============================================================================
# RESTART FIREWALL SERVICE
# =============================================================================

log "Restarting pve-firewall service..."

if systemctl restart pve-firewall.service; then
    success "Firewall service restarted"
else
    warn "Firewall service restart returned non-zero, checking status..."
fi

# Verify service status
if systemctl is-active --quiet pve-firewall.service; then
    success "pve-firewall.service is active"
else
    error "pve-firewall.service is not active!"
    systemctl status pve-firewall.service
fi

# =============================================================================
# VERIFY RULES APPLIED
# =============================================================================

log "Verifying iptables rules..."
echo ""

echo "Rules for port 8006 (API):"
iptables -L INPUT -n | grep -E "8006|dpt:8006" | head -5 || echo "  (no rules found)"
echo ""

echo "Rules for port 22 (SSH):"
iptables -L INPUT -n | grep -E "dpt:22[^0-9]|dpt:22$" | head -5 || echo "  (no rules found)"
echo ""

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "=============================================="
success "UGREEN Proxmox firewall fix complete!"
echo "=============================================="
echo ""
echo "Added access for:"
echo "  - LXC102 (192.168.40.82) → ports 22, 8006"
echo "  - Homelab (192.168.40.40) → ports 22, 8006"
echo ""
echo "Backup saved to: $BACKUP_FILE"
echo ""
echo "To verify from LXC102, run:"
echo "  ~/scripts/infrastructure/check-env-status.sh"
echo ""
echo "To rollback if needed:"
echo "  sudo cp $BACKUP_FILE $CLUSTER_FW"
echo "  sudo systemctl restart pve-firewall.service"
echo ""
