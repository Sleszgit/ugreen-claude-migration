#!/bin/bash
#
# Fix Subscription Popup - CORRECT VERSION
# Based on diagnostic output analysis
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
echo "Fix Subscription Popup - CORRECT"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Must run as root${NC}"
    exit 1
fi

# Check if ORIGINAL backup exists
if [ ! -f "$BACKUP_DIR/proxmoxlib.js.ORIGINAL" ]; then
    echo -e "${RED}ERROR: Original backup not found!${NC}"
    echo "Expected: $BACKUP_DIR/proxmoxlib.js.ORIGINAL"
    echo ""
    echo "Creating backup from current file..."
    mkdir -p "$BACKUP_DIR"
    cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.ORIGINAL"
    echo -e "${GREEN}✓${NC} Backup created"
fi

# Create timestamp backup
echo "=== Creating Backup ==="
mkdir -p "$BACKUP_DIR"
cp "$TARGET_FILE" "$BACKUP_DIR/proxmoxlib.js.before-fix-$TIMESTAMP"
echo -e "${GREEN}✓${NC} Current state backed up"

# Restore from original to start clean
echo ""
echo "=== Restoring Original File ==="
echo "This removes previous broken modifications..."
cp "$BACKUP_DIR/proxmoxlib.js.ORIGINAL" "$TARGET_FILE"
echo -e "${GREEN}✓${NC} Original file restored"

# Verify original is clean
echo ""
echo "=== Verifying Original State ==="
if grep -q "void({" "$TARGET_FILE"; then
    echo -e "${RED}✗${NC} Original file appears to have modifications!"
    echo "Cannot proceed - backup may be corrupted"
    exit 1
else
    echo -e "${GREEN}✓${NC} File is clean (no previous modifications)"
fi

# Show what we'll change
echo ""
echo "=== Target Code to Modify ==="
echo "Line 616 (approximately):"
grep -n "Ext\.Msg\.show" "$TARGET_FILE" | head -1
echo ""

echo "This will change:"
echo "  Ext.Msg.show({          (shows popup)"
echo "  ↓"
echo "  void({                  (disables popup)"
echo ""

read -p "Apply this fix? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled. Restoring previous state..."
    cp "$BACKUP_DIR/proxmoxlib.js.before-fix-$TIMESTAMP" "$TARGET_FILE"
    exit 0
fi

# Apply the fix
echo ""
echo "=== Applying Fix ==="

# Method: Replace ONLY the first occurrence of Ext.Msg.show in the checked_command function
# This is safer than replacing all occurrences

# Find the line number of checked_command
CHECKED_LINE=$(grep -n "checked_command.*function" "$TARGET_FILE" | head -1 | cut -d: -f1)

if [ -z "$CHECKED_LINE" ]; then
    echo -e "${RED}✗${NC} Cannot find checked_command function!"
    cp "$BACKUP_DIR/proxmoxlib.js.before-fix-$TIMESTAMP" "$TARGET_FILE"
    exit 1
fi

echo "checked_command function starts at line: $CHECKED_LINE"

# Use sed to replace Ext.Msg.show with void( ONLY in the subscription check area (around line 616)
# We'll target lines 615-620 to be safe
sed -i '615,620s/Ext\.Msg\.show({/void({ \/\/ Subscription popup disabled/g' "$TARGET_FILE"

echo -e "${GREEN}✓${NC} Modification applied"

# Verify the fix worked
echo ""
echo "=== Verifying Fix ==="

# Check line ~616 now has 'void({'
if sed -n '615,620p' "$TARGET_FILE" | grep -q "void({"; then
    echo -e "${GREEN}✓${NC} Popup successfully disabled"
    echo ""
    echo "Modified code:"
    sed -n '615,620p' "$TARGET_FILE" | grep --color=auto "void({"
else
    echo -e "${RED}✗${NC} Fix verification failed!"
    echo "Restoring backup..."
    cp "$BACKUP_DIR/proxmoxlib.js.before-fix-$TIMESTAMP" "$TARGET_FILE"
    exit 1
fi

# Check for syntax errors (basic check)
if grep -q "}void({ ," "$TARGET_FILE"; then
    echo -e "${RED}✗${NC} Detected broken syntax!"
    cp "$BACKUP_DIR/proxmoxlib.js.before-fix-$TIMESTAMP" "$TARGET_FILE"
    exit 1
fi

# Restart pveproxy
echo ""
echo "=== Restarting pveproxy ==="
systemctl restart pveproxy.service
sleep 3

if systemctl is-active --quiet pveproxy; then
    echo -e "${GREEN}✓${NC} pveproxy restarted successfully"
else
    echo -e "${RED}✗${NC} pveproxy FAILED! Restoring backup..."
    cp "$BACKUP_DIR/proxmoxlib.js.before-fix-$TIMESTAMP" "$TARGET_FILE"
    systemctl restart pveproxy
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ SUCCESS! Popup disabled.${NC}"
echo "=========================================="
echo ""
echo "What was changed:"
echo "  - Line ~616: Ext.Msg.show → void"
echo "  - Popup: DISABLED"
echo "  - File: Clean (no broken syntax)"
echo ""
echo "To verify:"
echo "  1. Close ALL Proxmox browser tabs"
echo "  2. Clear browser cache: Ctrl+Shift+Delete"
echo "  3. Open: https://192.168.40.60:8006"
echo "  4. Login - popup should NOT appear"
echo ""
echo "Restore command (if needed):"
echo "  cp $BACKUP_DIR/proxmoxlib.js.ORIGINAL $TARGET_FILE"
echo "  systemctl restart pveproxy"
echo ""
