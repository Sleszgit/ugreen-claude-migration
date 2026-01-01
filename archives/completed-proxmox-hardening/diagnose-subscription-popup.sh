#!/bin/bash
#
# Diagnostic Script - Analyze Proxmox Subscription Popup Code
# This will show exactly what's in the file so we can create the correct fix
#

TARGET_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

echo "=========================================="
echo "Proxmox Subscription Popup Diagnostics"
echo "=========================================="
echo ""

# Check if file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "ERROR: File not found: $TARGET_FILE"
    exit 1
fi

echo "File: $TARGET_FILE"
echo "Size: $(du -h "$TARGET_FILE" | cut -f1)"
echo "Modified: $(stat -c %y "$TARGET_FILE")"
echo ""

# Find line numbers for key sections
echo "=========================================="
echo "1. SUBSCRIPTION TEXT SEARCH"
echo "=========================================="
echo ""
echo "Searching for subscription-related text:"
grep -n "subscription\|Subscription" "$TARGET_FILE" | head -20
echo ""

# Find the checked_command function
echo "=========================================="
echo "2. CHECKED_COMMAND FUNCTION"
echo "=========================================="
echo ""
echo "Finding checked_command function (this triggers the popup):"
CHECKED_LINE=$(grep -n "checked_command.*function" "$TARGET_FILE" | head -1 | cut -d: -f1)
if [ -n "$CHECKED_LINE" ]; then
    echo "Found at line: $CHECKED_LINE"
    echo ""
    echo "Function code (next 40 lines):"
    sed -n "${CHECKED_LINE},$((CHECKED_LINE+40))p" "$TARGET_FILE"
else
    echo "NOT FOUND!"
fi
echo ""

# Find Ext.Msg.show calls
echo "=========================================="
echo "3. EXT.MSG.SHOW CALLS"
echo "=========================================="
echo ""
echo "All Ext.Msg.show calls in file:"
grep -n "Ext\.Msg\.show" "$TARGET_FILE" | head -10
echo ""

# Check for already modified code
echo "=========================================="
echo "4. CHECK FOR EXISTING MODIFICATIONS"
echo "=========================================="
echo ""
echo "Looking for 'void({' (indicates previous modification attempt):"
if grep -q "void({" "$TARGET_FILE"; then
    echo "FOUND - File has been modified!"
    grep -n "void({" "$TARGET_FILE" | head -5
else
    echo "NOT FOUND - File appears to be original"
fi
echo ""

# Show the specific subscription check logic
echo "=========================================="
echo "5. SUBSCRIPTION STATUS CHECK"
echo "=========================================="
echo ""
echo "Looking for subscription status check logic:"
grep -n "status.*active\|active.*status" "$TARGET_FILE" | head -5
echo ""

# Find the popup message function
echo "=========================================="
echo "6. POPUP MESSAGE FUNCTION"
echo "=========================================="
echo ""
echo "Looking for 'No valid subscription' title:"
NO_SUB_LINE=$(grep -n "No valid subscription" "$TARGET_FILE" | head -1 | cut -d: -f1)
if [ -n "$NO_SUB_LINE" ]; then
    echo "Found at line: $NO_SUB_LINE"
    echo ""
    echo "Context (10 lines before and after):"
    sed -n "$((NO_SUB_LINE-10)),$((NO_SUB_LINE+10))p" "$TARGET_FILE" | cat -n
else
    echo "NOT FOUND!"
fi
echo ""

# Show getNoSubKeyHtml function
echo "=========================================="
echo "7. GETNOSUBKEYHTML FUNCTION"
echo "=========================================="
echo ""
echo "Looking for getNoSubKeyHtml function:"
NOSUB_FUNC=$(grep -n "getNoSubKeyHtml.*function\|getNoSubKeyHtml:" "$TARGET_FILE" | head -1 | cut -d: -f1)
if [ -n "$NOSUB_FUNC" ]; then
    echo "Found at line: $NOSUB_FUNC"
    echo ""
    echo "Function code (next 20 lines):"
    sed -n "${NOSUB_FUNC},$((NOSUB_FUNC+20))p" "$TARGET_FILE"
else
    echo "NOT FOUND!"
fi
echo ""

# Summary
echo "=========================================="
echo "DIAGNOSTIC SUMMARY"
echo "=========================================="
echo ""
echo "Key findings:"
echo "  - checked_command at line: ${CHECKED_LINE:-NOT FOUND}"
echo "  - 'No valid subscription' at line: ${NO_SUB_LINE:-NOT FOUND}"
echo "  - getNoSubKeyHtml at line: ${NOSUB_FUNC:-NOT FOUND}"
echo ""
echo "File state:"
if grep -q "void({" "$TARGET_FILE"; then
    echo "  - Previously modified: YES"
else
    echo "  - Previously modified: NO"
fi
echo ""
echo "=========================================="
echo "PASTE ALL OUTPUT ABOVE TO CLAUDE"
echo "=========================================="
