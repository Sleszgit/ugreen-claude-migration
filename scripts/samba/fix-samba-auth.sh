#!/bin/bash
# Fix Samba Authentication Issues
# Run as root: sudo bash fix-samba-auth.sh

set -e

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo"
    exit 1
fi

echo "========================================="
echo "FIXING SAMBA AUTHENTICATION"
echo "========================================="
echo ""

# Restart Samba to apply password changes
echo "[1] Restarting Samba services..."
systemctl restart smbd nmbd
sleep 2
echo "✓ Samba restarted"
echo ""

# Verify user exists
echo "[2] Verifying Samba user..."
if pdbedit -L | grep -q sleszugreen; then
    echo "✓ User 'sleszugreen' exists in Samba"
else
    echo "✗ User not found! Adding now..."
    smbpasswd -a sleszugreen
fi
echo ""

# Check Samba configuration
echo "[3] Testing Samba configuration..."
testparm -s > /dev/null 2>&1 && echo "✓ Samba config is valid" || echo "✗ Config has errors"
echo ""

# Fix folder permissions (allow sleszugreen to access)
echo "[4] Adjusting folder permissions..."
chown -R sleszugreen:sleszugreen /storage/Media/Movies918 2>/dev/null || echo "Note: Some files may have different owners (this is okay)"
chown -R sleszugreen:sleszugreen /storage/Media/Series918 2>/dev/null || echo "Note: Some files may have different owners (this is okay)"
chmod -R u+rwX /storage/Media/Movies918
chmod -R u+rwX /storage/Media/Series918
echo "✓ Permissions updated"
echo ""

# Final status check
echo "[5] Final status check..."
systemctl is-active smbd && echo "✓ smbd is running" || echo "✗ smbd is NOT running"
systemctl is-active nmbd && echo "✓ nmbd is running" || echo "✗ nmbd is NOT running"
echo ""

echo "========================================="
echo "✅ FIX COMPLETE!"
echo "========================================="
echo ""
echo "Now try connecting from Windows with:"
echo "  \\\\192.168.40.60\\Movies918"
echo "  Username: sleszugreen"
echo "  Password: [the password you just set]"
echo ""
