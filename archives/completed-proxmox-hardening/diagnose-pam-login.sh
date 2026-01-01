#!/bin/bash
#
# Diagnostic script for PAM authentication issues
# Checks why SSH PAM works but Web UI PAM login fails
#

echo "=========================================="
echo "PAM Authentication Diagnostic Script"
echo "=========================================="
echo ""

echo "=== 1. Check password status ==="
passwd -S sleszugreen
passwd -S root
echo ""

echo "=== 2. Check PAM configuration for Proxmox ==="
if [ -f /etc/pam.d/proxmox-ve-auth ]; then
    echo "Contents of /etc/pam.d/proxmox-ve-auth:"
    cat /etc/pam.d/proxmox-ve-auth
else
    echo "File /etc/pam.d/proxmox-ve-auth not found"
fi
echo ""

echo "=== 3. Check common-auth PAM config ==="
if [ -f /etc/pam.d/common-auth ]; then
    echo "Contents of /etc/pam.d/common-auth:"
    cat /etc/pam.d/common-auth
else
    echo "File /etc/pam.d/common-auth not found"
fi
echo ""

echo "=== 4. Check if sleszugreen account is locked ==="
passwd -S sleszugreen | grep -q " L " && echo "WARNING: Account is LOCKED!" || echo "Account is not locked (OK)"
echo ""

echo "=== 5. Check recent authentication failures in pveproxy logs ==="
echo "Last 20 authentication-related log entries:"
journalctl -u pveproxy --since "5 minutes ago" --no-pager | grep -i "auth\|login\|fail\|sleszugreen" | tail -20
echo ""

echo "=== 6. Check auth.log for PAM errors ==="
echo "Recent PAM authentication attempts for sleszugreen:"
grep "sleszugreen" /var/log/auth.log | tail -10
echo ""

echo "=== 7. Test PAM authentication directly ==="
echo "Attempting to validate sleszugreen can authenticate via PAM..."
echo "NOTE: This requires the password to be entered interactively"
echo ""
su - sleszugreen -c "echo 'PAM authentication successful'" 2>&1
echo ""

echo "=== 8. Check pvedaemon status ==="
systemctl status pvedaemon | head -15
echo ""

echo "=== 9. Check pveproxy status ==="
systemctl status pveproxy | head -15
echo ""

echo "=========================================="
echo "Diagnostic complete!"
echo ""
echo "NEXT STEPS:"
echo "1. Try to login to Web UI as sleszugreen@pam NOW"
echo "2. If it fails, immediately run:"
echo "   journalctl -u pveproxy --since '1 minute ago' --no-pager | tail -30"
echo "   This will capture the actual authentication failure details"
echo "=========================================="
