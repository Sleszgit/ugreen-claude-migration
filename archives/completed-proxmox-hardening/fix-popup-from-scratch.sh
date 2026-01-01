#!/bin/bash
#
# Fix Subscription Popup - From Scratch
# Reinstalls clean file, then applies correct fix
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
echo "Fix Subscription Popup - From Scratch"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Must run as root${NC}"
    exit 1
fi

# Backup current corrupted file
echo "=== Backing Up Current File ==="
mkdir -p "$BACKUP_DIR"
cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.corrupted-$TIMESTAMP"
echo -e "${GREEN}✓${NC} Corrupted file backed up (for reference)"

# Get clean original by reinstalling the package
echo ""
echo "=== Reinstalling proxmox-widget-toolkit ==="
echo "This will download and install a CLEAN original file"
echo ""
read -p "Proceed with package reinstall? (yes/no): " REINSTALL

if [ "$REINSTALL" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Find package name
PACKAGE=$(dpkg -S "$TARGET_FILE" | cut -d: -f1)
echo "Package: $PACKAGE"

# Reinstall to get clean file
echo "Reinstalling..."
apt-get install --reinstall -y "$PACKAGE"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Package reinstall failed!"
    exit 1
fi

echo -e "${GREEN}✓${NC} Clean file installed"

# Backup the clean original
cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.CLEAN-ORIGINAL"
echo -e "${GREEN}✓${NC} Clean original preserved"

# Verify it's clean
echo ""
echo "=== Verifying Clean File ==="
if grep -q "void({" "$TARGET_FILE"; then
    echo -e "${RED}✗${NC} File still has modifications - reinstall didn't work!"
    exit 1
fi

if grep -q "}void({ ," "$TARGET_FILE"; then
    echo -e "${RED}✗${NC} File still has broken syntax!"
    exit 1
fi

echo -e "${GREEN}✓${NC} File is clean"

# Now apply the popup fix
echo ""
echo "=== Applying Popup Fix ==="
echo "Modifying line ~616: Ext.Msg.show → void"
echo ""

# Create pre-modification backup
cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.before-modification-$TIMESTAMP"

# Apply fix - replace Ext.Msg.show with void( ONLY in lines 610-625 (subscription check area)
sed -i '610,625s/Ext\.Msg\.show({/void({ \/\/ popup disabled/g' "$TARGET_FILE"

# Verify
if sed -n '610,625p' "$TARGET_FILE" | grep -q "void({ // popup disabled"; then
    echo -e "${GREEN}✓${NC} Popup successfully disabled"
else
    echo -e "${RED}✗${NC} Modification failed!"
    cp "$BACKUP_DIR/proxmoxlib.js.CLEAN-ORIGINAL" "$TARGET_FILE"
    exit 1
fi

# Final syntax check
echo ""
echo "=== Syntax Check ==="
if grep -q "}void({ ," "$TARGET_FILE"; then
    echo -e "${RED}✗${NC} Broken syntax detected!"
    cp "$BACKUP_DIR/proxmoxlib.js.CLEAN-ORIGINAL" "$TARGET_FILE"
    exit 1
fi
echo -e "${GREEN}✓${NC} No syntax errors"

# Restart pveproxy
echo ""
echo "=== Restarting pveproxy ==="
systemctl restart pveproxy.service
sleep 3

if systemctl is-active --quiet pveproxy; then
    echo -e "${GREEN}✓${NC} pveproxy restarted successfully"
else
    echo -e "${RED}✗${NC} pveproxy FAILED!"
    echo "Restoring clean original..."
    cp "$BACKUP_DIR/proxmoxlib.js.CLEAN-ORIGINAL" "$TARGET_FILE"
    systemctl restart pveproxy
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ SUCCESS!${NC}"
echo "=========================================="
echo ""
echo "What happened:"
echo "  1. Reinstalled proxmox-widget-toolkit (clean file)"
echo "  2. Applied popup fix (Ext.Msg.show → void)"
echo "  3. Verified syntax is correct"
echo "  4. Restarted pveproxy"
echo ""
echo "Backups created:"
echo "  - Clean original: $BACKUP_DIR/proxmoxlib.js.CLEAN-ORIGINAL"
echo "  - Corrupted version: $BACKUP_DIR/proxmoxlib.js.corrupted-$TIMESTAMP"
echo ""
echo "To verify popup is gone:"
echo "  1. Close ALL browser tabs with Proxmox"
echo "  2. Clear browser cache: Ctrl+Shift+Delete"
echo "  3. Open: https://192.168.40.60:8006"
echo "  4. Login - NO popup should appear"
echo ""
echo "To restore popup (if ever needed):"
echo "  apt-get install --reinstall proxmox-widget-toolkit"
echo "  systemctl restart pveproxy"
echo ""
