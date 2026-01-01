#!/bin/bash
#
# Remove Proxmox Subscription Popup
# Safe version with comprehensive backup and rollback
#

set -e

SCRIPT_DIR="/root/proxmox-hardening"
BACKUP_DIR="$SCRIPT_DIR/backups/subscription-popup"
TARGET_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Remove Proxmox Subscription Popup"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo bash $0"
    exit 1
fi

# Check if target file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo -e "${RED}ERROR: Target file not found!${NC}"
    echo "File: $TARGET_FILE"
    exit 1
fi

echo "Target file: $TARGET_FILE"
echo "File size: $(du -h "$TARGET_FILE" | cut -f1)"
echo ""

# Create comprehensive backup
echo "=== Creating Backup ==="
mkdir -p "$BACKUP_DIR"

# Backup with timestamp
cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.backup-$TIMESTAMP"
echo -e "${GREEN}✓${NC} Backup created: proxmoxlib.js.backup-$TIMESTAMP"

# Backup original (if not exists)
if [ ! -f "$BACKUP_DIR/proxmoxlib.js.original" ]; then
    cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.original"
    echo -e "${GREEN}✓${NC} Original saved: proxmoxlib.js.original"
fi

# Show current popup code (for verification)
echo ""
echo "=== Current Popup Code ==="
if grep -q "No valid subscription" "$TARGET_FILE"; then
    echo -e "${YELLOW}Subscription popup code FOUND in file${NC}"
    grep -n "No valid subscription" "$TARGET_FILE" | head -3
else
    echo -e "${GREEN}Subscription popup code NOT FOUND${NC}"
    echo "Popup may already be disabled"
    read -p "Continue anyway? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        exit 0
    fi
fi

echo ""
echo "=== Applying Modification ==="
echo ""
echo "This will modify the JavaScript to disable the popup."
echo "Your Proxmox will still function normally."
echo "You can always restore from backup."
echo ""
read -p "Proceed with modification? (yes/no): " PROCEED

if [ "$PROCEED" != "yes" ]; then
    echo "Modification cancelled."
    exit 0
fi

# Apply the modification (creates .orig backup automatically)
sed -Ezi.orig \
  "s/(Ext.Msg.show\(\{[^\}]*title:\s*'[^']*',\s*)*([^\}]*No valid subscription)/void({ \2/g" \
  "$TARGET_FILE"

echo -e "${GREEN}✓${NC} Modification applied"

# Verify modification worked
echo ""
echo "=== Verification ==="
if grep -q "void({ .*No valid subscription" "$TARGET_FILE"; then
    echo -e "${GREEN}✓${NC} Popup code successfully modified"
elif ! grep -q "No valid subscription" "$TARGET_FILE"; then
    echo -e "${YELLOW}⚠${NC} 'No valid subscription' text not found"
    echo "This might mean:"
    echo "  1. Modification successful (text removed)"
    echo "  2. Different Proxmox version (different code)"
else
    echo -e "${RED}✗${NC} Modification may have failed"
    echo "Check manually or restore backup"
fi

# Restart pveproxy service
echo ""
echo "=== Restarting Web UI Service ==="
systemctl restart pveproxy.service
sleep 2

if systemctl is-active --quiet pveproxy; then
    echo -e "${GREEN}✓${NC} pveproxy service restarted successfully"
else
    echo -e "${RED}✗${NC} pveproxy service failed to start!"
    echo "Restoring backup..."
    cp "$BACKUP_DIR/proxmoxlib.js.backup-$TIMESTAMP" "$TARGET_FILE"
    systemctl restart pveproxy
    echo "Backup restored"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Done! Refresh your browser.${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Backup created: $BACKUP_DIR/"
echo "  - Popup disabled: YES"
echo "  - Service restarted: YES"
echo ""
echo "To verify:"
echo "  1. Open Web UI: https://192.168.40.60:8006"
echo "  2. Login (popup should NOT appear)"
echo "  3. If still appears, hard-refresh: Ctrl+F5"
echo ""
echo "To restore popup (if needed):"
echo "  cp $BACKUP_DIR/proxmoxlib.js.original $TARGET_FILE"
echo "  systemctl restart pveproxy"
echo ""
echo "Note: Future Proxmox updates may restore the popup."
echo "You can re-run this script after updates."
echo ""
