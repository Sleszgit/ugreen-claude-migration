#!/bin/bash

################################################################################
# UGREEN Proxmox VLAN 10 Configuration - FIXED VERSION
# Creates vmbr0.10 as a proper bridge device (not just VLAN interface)
#
# This script:
# 1. Backs up current network config
# 2. Creates vmbr0.10 as a Linux bridge on VLAN 10
# 3. Assigns IP 10.10.10.40/24 to vmbr0.10
# 4. Modifies VM 100 to use vmbr0.10 with tag=10
# 5. Reboots VM 100 and verifies it's running
################################################################################

set -e  # Exit on any error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

echo "════════════════════════════════════════════════════════════════════════════"
echo "UGREEN Proxmox VLAN 10 Configuration (FIXED - Proper Bridge)"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Backup
echo -e "${YELLOW}[STEP 1]${NC} Backing up current network configuration..."
BACKUP_FILE="/etc/network/interfaces.backup.$(date +%Y%m%d-%H%M%S)"
cp /etc/network/interfaces "$BACKUP_FILE"
echo -e "${GREEN}✓${NC} Backup created: $BACKUP_FILE"
echo ""

# Step 2: Show current config
echo -e "${YELLOW}[STEP 2]${NC} Current network configuration..."
echo "─────────────────────────────────"
cat /etc/network/interfaces
echo "─────────────────────────────────"
echo ""

# Step 3: Check if vmbr0.10 exists
echo -e "${YELLOW}[STEP 3]${NC} Checking if vmbr0.10 already exists..."
if ip link show vmbr0.10 &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} vmbr0.10 already exists, skipping creation"
else
    echo -e "${GREEN}✓${NC} vmbr0.10 does not exist yet (will be created)"
fi
echo ""

# Step 4: Add VLAN 10 as a PROPER BRIDGE (not just interface)
echo -e "${YELLOW}[STEP 4]${NC} Adding VLAN 10 bridge configuration..."
cat >> /etc/network/interfaces << 'EOF'

auto vmbr0.10
iface vmbr0.10 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    vlan-raw-device vmbr0

auto vmbr0.10:0
iface vmbr0.10:0 inet static
    address 10.10.10.40/24
EOF
echo -e "${GREEN}✓${NC} VLAN 10 bridge configuration added"
echo ""

# Step 5: Verify syntax
echo -e "${YELLOW}[STEP 5]${NC} Verifying network configuration syntax..."
if ! ip -o link show vmbr0 &>/dev/null; then
    echo -e "${RED}✗${NC} Syntax issue detected!"
    echo "Restoring from backup..."
    cp "$BACKUP_FILE" /etc/network/interfaces
    exit 1
fi
echo -e "${GREEN}✓${NC} Syntax looks good"
echo ""

# Step 6: Show new config
echo -e "${YELLOW}[STEP 6]${NC} New vmbr0.10 configuration added:"
echo "─────────────────────────────────"
tail -10 /etc/network/interfaces
echo "─────────────────────────────────"
echo ""

# Step 7: Restart networking
echo -e "${YELLOW}[STEP 7]${NC} Restarting networking to apply VLAN configuration..."
echo "⏳ This may take 10-15 seconds..."
systemctl restart networking
sleep 3
echo -e "${GREEN}✓${NC} Networking restarted successfully"
echo ""

# Step 8: Verify VLAN bridge was created
echo -e "${YELLOW}[STEP 8]${NC} Verifying vmbr0.10 bridge was created..."
if ip link show vmbr0.10 &>/dev/null; then
    echo -e "${GREEN}✓${NC} vmbr0.10 is UP"
    echo "    $(ip addr show vmbr0.10 | grep inet | sed 's/^[[:space:]]*//')"
else
    echo -e "${RED}✗${NC} vmbr0.10 not found!"
    echo "Restoring from backup and exiting..."
    cp "$BACKUP_FILE" /etc/network/interfaces
    systemctl restart networking
    exit 1
fi
echo ""

# Step 9: Get current VM 100 config
echo -e "${YELLOW}[STEP 9]${NC} Getting current VM 100 network configuration..."
CURRENT_CONFIG=$(qm config 100 | grep net0)
echo "Current: $CURRENT_CONFIG"
echo ""

# Step 10: Modify VM 100 network interface
echo -e "${YELLOW}[STEP 10]${NC} Modifying VM 100 network interface to use vmbr0.10..."
qm set 100 --net0 virtio=BC:24:11:8B:FD:EC,bridge=vmbr0.10,tag=10,firewall=1
echo -e "${GREEN}✓${NC} VM 100 network configuration updated"
echo ""

# Step 11: Verify VM config was updated
echo -e "${YELLOW}[STEP 11]${NC} Verifying VM 100 configuration..."
NEW_CONFIG=$(qm config 100 | grep net0)
echo "New: $NEW_CONFIG"
echo ""

# Step 12: Reboot VM 100
echo -e "${YELLOW}[STEP 12]${NC} Rebooting VM 100 to apply network changes..."
qm reboot 100
echo "⏳ Waiting 30 seconds for VM to restart..."
sleep 30
echo -e "${GREEN}✓${NC} Reboot command sent"
echo ""

# Step 13: Verify VM is running
echo -e "${YELLOW}[STEP 13]${NC} Verifying VM 100 status..."
VM_STATUS=$(qm status 100)
echo "Status: $VM_STATUS"
if echo "$VM_STATUS" | grep -q "running"; then
    echo -e "${GREEN}✓${NC} VM 100 is running"
else
    echo -e "${YELLOW}⚠${NC} VM 100 may still be booting, checking in 10 seconds..."
    sleep 10
    qm status 100
fi
echo ""

# Step 14: Summary
echo "════════════════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ VLAN 10 CONFIGURATION COMPLETE${NC}"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Summary:"
echo "  • VLAN 10 Bridge: vmbr0.10 (bridge device)"
echo "  • VLAN 10 IP: 10.10.10.40/24"
echo "  • VM 100 Network: virtio via vmbr0.10 (tagged VLAN 10)"
echo "  • VM 100 Status: $(qm status 100 | grep -oP 'status: \K\w+')"
echo ""
echo "Next steps:"
echo "  1. Check VM 100 has IP 10.10.10.100 configured"
echo "  2. Test connectivity from LXC 102: ssh sleszdockerugreen@10.10.10.100"
echo "  3. Then run Phase B hardening scripts"
echo ""
