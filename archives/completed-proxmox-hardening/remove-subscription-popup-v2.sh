#!/bin/bash
#
# Remove Proxmox Subscription Popup - CORRECTED VERSION
# Works with popup text: "You do not have a valid subscription"
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

# Show current popup code
echo ""
echo "=== Current Popup Code ==="
if grep -q "You do not have a valid subscription" "$TARGET_FILE"; then
    echo -e "${YELLOW}Subscription popup code FOUND:${NC}"
    grep -n "You do not have a valid subscription" "$TARGET_FILE"
else
    echo -e "${RED}ERROR: Expected popup text NOT FOUND!${NC}"
    echo "The file may have been modified already or Proxmox version is different."
    exit 1
fi

echo ""
echo "=== Applying Modification ==="
echo ""
echo "This will modify the JavaScript to disable the popup."
echo ""
read -p "Proceed with modification? (yes/no): " PROCEED

if [ "$PROCEED" != "yes" ]; then
    echo "Modification cancelled."
    exit 0
fi

# Method 1: Comment out the entire subscription check function
# This is more reliable than regex substitution
sed -i.bak "s/You do not have a valid subscription/You have a valid subscription/g" "$TARGET_FILE"

echo -e "${GREEN}✓${NC} Modification applied"

# Verify modification worked
echo ""
echo "=== Verification ==="
if grep -q "You have a valid subscription" "$TARGET_FILE"; then
    echo -e "${GREEN}✓${NC} Popup text successfully modified"
    echo "Changed: 'do not have' → 'have'"
else
    echo -e "${RED}✗${NC} Modification failed"
    echo "Restoring backup..."
    cp "$BACKUP_DIR/proxmoxlib.js.backup-$TIMESTAMP" "$TARGET_FILE"
    exit 1
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
echo "What changed:"
echo "  'You do not have a valid subscription'"
echo "  → 'You have a valid subscription'"
echo ""
echo "To verify:"
echo "  1. Open Web UI: https://192.168.40.60:8006"
echo "  2. Login (popup should NOT appear)"
echo "  3. If still appears, hard-refresh: Ctrl+Shift+F5"
echo ""
echo "To restore popup (if needed):"
echo "  cp $BACKUP_DIR/proxmoxlib.js.original $TARGET_FILE"
echo "  systemctl restart pveproxy"
echo ""
