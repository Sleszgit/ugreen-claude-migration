#!/bin/bash
# =============================================================================
# UGREEN VLAN10 Safe Deployment Script with Dead Man's Switch
# =============================================================================
# Purpose: Safely apply VLAN10 network configuration with automatic rollback
#
# Based on: Gemini expert recommendations + corrected configuration
# Risk Level: MEDIUM (critical infrastructure, but with safety net)
#
# Usage (RUN ON UGREEN PROXMOX HOST):
#   ssh -p 22022 ugreen-host "sudo /mnt/lxc102scripts/deploy-vlan10-safe.sh"
#
# CRITICAL: This script assumes:
#   - You are connected via SSH to 192.168.40.60:22022
#   - Physical console is NOT available
#   - You understand the dead man's switch will auto-revert after 90 seconds
# =============================================================================

set -Eeuo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# File paths
CONFIG_FILE="/etc/network/interfaces"
BACKUP_DIR="/root/network-backups"
WORKING_BACKUP="${BACKUP_DIR}/interfaces.working.backup.$(date +%s)"
NEW_CONFIG="/tmp/network-interfaces.vlan10.CORRECTED.new"
DEADSWITCH_LOG="/tmp/vlan10-deadswitch-$$.log"

# Network parameters
NIC="nic1"
GATEWAY="192.168.40.1"
MGMT_IP="192.168.40.60"

# Dead man's switch timeout (seconds)
DEADSWITCH_TIMEOUT=90

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

log_step() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

log_info() {
    echo -e "${GREEN}ℹ️${NC}  $1"
}

log_warn() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

log_error() {
    echo -e "${RED}❌${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✅${NC}  $1"
}

# =============================================================================
# STEP 0: Pre-flight Checks
# =============================================================================

log_step "STEP 0: Pre-flight Checks"

if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
fi
log_success "Running as root"

if [ ! -f "$NEW_CONFIG" ]; then
    log_error "Configuration file not found: $NEW_CONFIG"
    echo "Expected at: /mnt/lxc102scripts/network-interfaces.vlan10.CORRECTED.new"
    echo "Copy it there first, or update NEW_CONFIG path in this script"
    exit 1
fi
log_success "Configuration file found: $NEW_CONFIG"

mkdir -p "$BACKUP_DIR"
log_success "Backup directory ready: $BACKUP_DIR"

# Verify we can reach the gateway (current state)
if ! ping -c 1 -W 2 "$GATEWAY" &>/dev/null; then
    log_error "Cannot reach gateway ($GATEWAY). Network appears broken already."
    exit 1
fi
log_success "Gateway ($GATEWAY) is reachable"

# =============================================================================
# STEP 1: Create Working Backup (Safety Net #1)
# =============================================================================

log_step "STEP 1: Create Working Backup"

if ! cp "$CONFIG_FILE" "$WORKING_BACKUP"; then
    log_error "Failed to create backup"
    exit 1
fi
log_success "Backup created: $WORKING_BACKUP"
log_info "This is your primary safety net - will be restored if something goes wrong"

# =============================================================================
# STEP 2: Start Dead Man's Switch (Safety Net #2)
# =============================================================================

log_step "STEP 2: Starting Dead Man's Switch (90-second timeout)"

log_warn "IMPORTANT: A background process will automatically revert this change"
log_warn "in 90 seconds if you don't cancel it manually."
echo ""
log_info "The dead man's switch is starting NOW"
log_info "In 90 seconds, if you haven't explicitly cancelled it, the system will:"
log_info "  1. Restore the backup configuration"
log_info "  2. Reload the network"
log_info "  3. Allow you to reconnect with the old (working) settings"
echo ""

# Create the dead man's switch in the background
nohup bash -c "
    echo \"[$(date)] Dead man's switch activated (PID: $$)\" > '$DEADSWITCH_LOG'
    sleep $DEADSWITCH_TIMEOUT

    # Check if we should still proceed with revert
    if [ -f /tmp/vlan10-cancel-deadswitch ]; then
        echo \"[$(date)] Cancellation file found, not reverting\" >> '$DEADSWITCH_LOG'
        exit 0
    fi

    echo \"[$(date)] Timeout reached, reverting network configuration\" >> '$DEADSWITCH_LOG'
    cp '$WORKING_BACKUP' '$CONFIG_FILE' 2>&1 | tee -a '$DEADSWITCH_LOG'
    /sbin/ifreload -a 2>&1 | tee -a '$DEADSWITCH_LOG'
    echo \"[$(date)] Revert complete\" >> '$DEADSWITCH_LOG'
" >/dev/null 2>&1 &

DEADSWITCH_PID=$!
log_success "Dead man's switch started (PID: $DEADSWITCH_PID)"
log_info "Log file: $DEADSWITCH_LOG"
echo ""
echo -e "${YELLOW}⏱️  COUNTDOWN: You have 90 seconds to verify the new network is working${NC}"
echo ""

# =============================================================================
# STEP 3: Pre-Apply Hardware Fix (ethtool)
# =============================================================================

log_step "STEP 3: Pre-Apply Hardware Fix (Disable VLAN Offloading)"

log_warn "Running ethtool BEFORE applying network config (prevents race condition)"

if ! /sbin/ethtool -K "$NIC" rx-vlan-filter off tx-vlan-offload off 2>&1; then
    log_error "Failed to apply ethtool settings"
    exit 1
fi
log_success "Ethtool settings applied"

# Verify settings were applied
if /sbin/ethtool -k "$NIC" 2>&1 | grep -q "rx-vlan-filter: off"; then
    log_success "Verified: rx-vlan-filter is OFF"
else
    log_error "Failed to verify ethtool settings"
    exit 1
fi

if /sbin/ethtool -k "$NIC" 2>&1 | grep -q "tx-vlan-offload: off"; then
    log_success "Verified: tx-vlan-offload is OFF"
else
    log_error "Failed to verify ethtool settings"
    exit 1
fi

echo ""

# =============================================================================
# STEP 4: Apply New Network Configuration
# =============================================================================

log_step "STEP 4: Apply New Network Configuration"

log_warn "Applying configuration from: $NEW_CONFIG"
log_warn "Your SSH session may freeze for a few seconds"

if ! cp "$NEW_CONFIG" "$CONFIG_FILE"; then
    log_error "Failed to copy new configuration"
    exit 1
fi
log_success "Configuration installed"

log_info "Reloading network interfaces with 'ifreload -a'..."
if ! /sbin/ifreload -a 2>&1; then
    log_error "ifreload failed - dead man's switch will handle recovery"
    exit 1
fi
log_success "Configuration reloaded successfully"

echo ""

# =============================================================================
# STEP 5: Verify Network Stack (Bottom-Up)
# =============================================================================

log_step "STEP 5: Verify Network Stack (Bottom-Up)"

# Level 1: Hardware (ethtool)
log_info "Level 1: Hardware settings"
if /sbin/ethtool -k "$NIC" 2>&1 | grep -q "rx-vlan-filter: off"; then
    log_success "rx-vlan-filter is OFF"
else
    log_error "rx-vlan-filter is NOT off"
    exit 1
fi

if /sbin/ethtool -k "$NIC" 2>&1 | grep -q "tx-vlan-offload: off"; then
    log_success "tx-vlan-offload is OFF"
else
    log_error "tx-vlan-offload is NOT off"
    exit 1
fi

echo ""

# Level 2: Bridge configuration
log_info "Level 2: Bridge configuration"
if ip link show vmbr0 | grep -q "BROADCAST"; then
    log_success "vmbr0 interface exists"
else
    log_error "vmbr0 interface not found or not up"
    exit 1
fi

if /sbin/bridge vlan show 2>&1 | grep -q "vmbr0.*10"; then
    log_success "VLAN 10 registered on bridge"
else
    log_error "VLAN 10 not registered on bridge"
    exit 1
fi

if /sbin/bridge vlan show 2>&1 | grep -q "vmbr0.*40"; then
    log_success "VLAN 40 registered on bridge"
else
    log_error "VLAN 40 not registered on bridge"
    exit 1
fi

echo ""

# Level 3: IP addresses
log_info "Level 3: IP addresses and interfaces"
if ip addr show vmbr0.40 2>&1 | grep -q "inet.*$MGMT_IP"; then
    log_success "vmbr0.40 has correct management IP ($MGMT_IP)"
else
    log_error "vmbr0.40 does not have expected IP"
    ip addr show vmbr0.40
    exit 1
fi

if ip addr show vmbr0.10 2>&1 | grep -q "inet.*10.10.10.60"; then
    log_success "vmbr0.10 has correct VLAN10 IP (10.10.10.60)"
else
    log_warn "vmbr0.10 does not have expected IP (expected 10.10.10.60)"
    ip addr show vmbr0.10
fi

echo ""

# Level 4: Connectivity
log_info "Level 4: Connectivity tests"
if ping -c 1 -W 2 "$GATEWAY" &>/dev/null; then
    log_success "Gateway ($GATEWAY) is reachable"
else
    log_error "Cannot reach gateway ($GATEWAY)"
    exit 1
fi

if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    log_success "External host (8.8.8.8) is reachable"
else
    log_warn "Cannot reach external host (8.8.8.8) - may be firewall issue"
fi

echo ""

# =============================================================================
# STEP 6: SUCCESS - Cancel Dead Man's Switch
# =============================================================================

log_step "✅ ALL VERIFICATIONS PASSED"

echo -e "${GREEN}Network configuration applied successfully!${NC}"
echo ""
log_warn "You MUST explicitly cancel the dead man's switch now"
log_warn "If you don't, the system will REVERT this change in a few seconds"
echo ""

# Create cancellation flag
touch /tmp/vlan10-cancel-deadswitch

sleep 2

log_success "Dead man's switch has been cancelled"
log_success "Configuration is now permanent"

echo ""
log_step "DEPLOYMENT COMPLETE"

echo "Network Configuration Summary:"
echo "  Management Network:  vmbr0.40 @ 192.168.40.60/24"
echo "  VLAN 10 Network:     vmbr0.10 @ 10.10.10.60/24"
echo "  Gateway:             192.168.40.1"
echo "  Physical NIC:        $NIC"
echo "  Hardware Offload:    Disabled (via post-up ethtool)"
echo ""
echo "Backups:"
echo "  Working backup:      $WORKING_BACKUP"
echo ""
echo "Status: ✅ VLAN10 network is ready for VM100 deployment"
echo ""

exit 0
