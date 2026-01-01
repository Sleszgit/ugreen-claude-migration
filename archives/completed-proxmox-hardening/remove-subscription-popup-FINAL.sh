#!/bin/bash
#
# Remove Proxmox Subscription Popup - FINAL WORKING VERSION
# Disables the actual Ext.Msg.show popup trigger
#

set -e

BACKUP_DIR="/root/proxmox-hardening/backups/subscription-popup"
TARGET_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Remove Proxmox Subscription Popup - FINAL"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    exit 1
fi

# Check if target file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo -e "${RED}ERROR: Target file not found: $TARGET_FILE${NC}"
    exit 1
fi

# Create backup
echo "=== Creating Backup ==="
mkdir -p "$BACKUP_DIR"
cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.backup-$TIMESTAMP"
echo -e "${GREEN}✓${NC} Backup: proxmoxlib.js.backup-$TIMESTAMP"

if [ ! -f "$BACKUP_DIR/proxmoxlib.js.ORIGINAL" ]; then
    cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.ORIGINAL"
    echo -e "${GREEN}✓${NC} Original preserved: proxmoxlib.js.ORIGINAL"
fi

# Check current state
echo ""
echo "=== Checking Current State ==="
if grep -q "Ext.Msg.show({" "$TARGET_FILE" | grep -q "title: gettext('No valid subscription')"; then
    echo -e "${YELLOW}Popup code FOUND - will be disabled${NC}"
elif grep -q "void({ .*title: gettext('No valid subscription')" "$TARGET_FILE"; then
    echo -e "${GREEN}Popup already disabled!${NC}"
    read -p "Re-apply fix anyway? (yes/no): " REAPPLY
    if [ "$REAPPLY" != "yes" ]; then
        exit 0
    fi
fi

echo ""
echo "=== Applying Fix ==="
echo "This will replace Ext.Msg.show with void( to disable the popup."
echo ""
read -p "Proceed? (yes/no): " PROCEED

if [ "$PROCEED" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# The actual fix - replace Ext.Msg.show with void(
# This makes the popup function call a no-op
sed -i.bak2 "s/Ext\.Msg\.show({/void({ /g" "$TARGET_FILE"

echo -e "${GREEN}✓${NC} Modification applied"

# Verify
echo ""
echo "=== Verification ==="
if grep -q "void({ " "$TARGET_FILE"; then
    echo -e "${GREEN}✓${NC} Popup successfully disabled (Ext.Msg.show → void)"
else
    echo -e "${RED}✗${NC} Fix may have failed"
fi

# Restart pveproxy
echo ""
echo "=== Restarting pveproxy ==="
systemctl restart pveproxy.service
sleep 3

if systemctl is-active --quiet pveproxy; then
    echo -e "${GREEN}✓${NC} pveproxy restarted successfully"
else
    echo -e "${RED}✗${NC} pveproxy FAILED to start - restoring backup!"
    cp "$BACKUP_DIR/proxmoxlib.js.backup-$TIMESTAMP" "$TARGET_FILE"
    systemctl restart pveproxy
    echo "Backup restored"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ DONE! Clear browser cache and refresh.${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Changed: Ext.Msg.show → void"
echo "  - Popup: DISABLED"
echo "  - Service: RESTARTED"
echo ""
echo "To verify:"
echo "  1. Close all Proxmox browser tabs"
echo "  2. Clear browser cache (Ctrl+Shift+Delete)"
echo "  3. Open: https://192.168.40.60:8006"
echo "  4. Login - NO popup should appear"
echo ""
echo "Restore command (if needed):"
echo "  cp $BACKUP_DIR/proxmoxlib.js.ORIGINAL $TARGET_FILE"
echo "  systemctl restart pveproxy"
echo ""
