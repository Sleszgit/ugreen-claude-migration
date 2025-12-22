#!/bin/bash
# Samba Diagnostics Script
# Run as root: sudo bash diagnose-samba.sh

echo "========================================="
echo "SAMBA DIAGNOSTICS"
echo "========================================="
echo ""

# Check if root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo:"
    echo "  sudo bash diagnose-samba.sh"
    exit 1
fi

echo "[1] Samba Service Status:"
systemctl status smbd --no-pager | grep -E "Active:|Main PID"
systemctl status nmbd --no-pager | grep -E "Active:|Main PID"
echo ""

echo "[2] Network Ports (should show 445 and 139):"
ss -tlnp | grep -E "445|139"
echo ""

echo "[3] Samba Users:"
pdbedit -L
echo ""

echo "[4] Samba Configuration Test:"
testparm -s 2>&1 | grep -E "workgroup|security|interfaces" | head -5
echo ""

echo "[5] Available Shares:"
smbclient -L localhost -N 2>&1 | grep -E "Sharename|Movies918|Series918|Media"
echo ""

echo "[6] Test Authentication for sleszugreen:"
echo "Testing if user can authenticate..."
smbclient //localhost/Movies918 -U sleszugreen%test 2>&1 | head -3
echo ""

echo "[7] Permissions on Media folders:"
ls -ld /storage/Media/Movies918 /storage/Media/Series918
echo ""

echo "[8] Network connectivity test:"
echo "IP Address: $(hostname -I)"
echo "Testing if port 445 is reachable..."
timeout 2 bash -c "</dev/tcp/192.168.40.60/445" && echo "✓ Port 445 is open" || echo "✗ Port 445 is not accessible"
echo ""

echo "========================================="
echo "DIAGNOSTICS COMPLETE"
echo "========================================="
