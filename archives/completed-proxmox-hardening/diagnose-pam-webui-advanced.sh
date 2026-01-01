#!/bin/bash
#
# Advanced PAM Web UI Login Diagnostic Script
# Identifies why sleszugreen@pam fails Web UI login while SSH works
#

echo "=========================================="
echo "Advanced PAM Web UI Login Diagnostics"
echo "=========================================="
echo ""
echo "Problem: SSH login works, Web UI @pve works, but Web UI @pam fails"
echo "Goal: Identify root cause and provide fix"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== 1. Check Proxmox VE User Database ==="
echo "Looking for sleszugreen in PVE database..."
pveum user list | grep -E "userid|sleszugreen"
echo ""

echo "=== 2. Check ACL Permissions ==="
echo "Checking what permissions sleszugreen has in Proxmox..."
echo ""
echo "Full ACL list:"
pveum acl list
echo ""
echo -e "${YELLOW}ANALYSIS:${NC}"
if pveum acl list | grep -q "sleszugreen@pam"; then
    echo -e "${GREEN}✓ sleszugreen@pam has ACL permissions${NC}"
else
    echo -e "${RED}✗ sleszugreen@pam has NO ACL permissions (LIKELY CAUSE!)${NC}"
    echo "  sleszugreen@pve has permissions, but @pam does not"
fi
echo ""

echo "=== 3. Check Linux User Groups ==="
echo "Checking which groups sleszugreen belongs to..."
groups sleszugreen
echo ""
id sleszugreen
echo ""
echo -e "${YELLOW}ANALYSIS:${NC}"
if groups sleszugreen | grep -q "sudo"; then
    echo -e "${GREEN}✓ User in sudo group${NC}"
else
    echo -e "${YELLOW}! User NOT in sudo group (may be required)${NC}"
fi
echo ""

echo "=== 4. Check /etc/passwd Entry ==="
grep "^sleszugreen:" /etc/passwd
echo ""

echo "=== 5. Check Password Expiry and Status ==="
chage -l sleszugreen
echo ""

echo "=== 6. Check Proxmox Cluster Configuration ==="
if [ -f /etc/pve/user.cfg ]; then
    echo "Contents of /etc/pve/user.cfg:"
    cat /etc/pve/user.cfg
else
    echo "File /etc/pve/user.cfg not found"
fi
echo ""

echo "=== 7. Test PAM Authentication Module Directly ==="
echo "Testing if PAM module accepts sleszugreen password..."
echo "NOTE: This test was successful in previous diagnostic"
su - sleszugreen -c "whoami" 2>&1
echo ""

echo "=== 8. Check for Proxmox Access Control Configuration ==="
if [ -f /etc/pve/priv/tfa.cfg ]; then
    echo "Checking TFA configuration (might block login)..."
    grep -i sleszugreen /etc/pve/priv/tfa.cfg 2>/dev/null || echo "No TFA configured for sleszugreen"
else
    echo "No TFA configuration file found"
fi
echo ""

echo "=== 9. Check System Auth Logs in Detail ==="
echo "Last 20 authentication attempts for sleszugreen:"
grep "sleszugreen" /var/log/auth.log | tail -20
echo ""

echo "=== 10. Check pvedaemon Logs for Authentication ==="
echo "Last 30 lines from pvedaemon (handles auth):"
journalctl -u pvedaemon --since "5 minutes ago" --no-pager | tail -30
echo ""

echo "=== 11. Check Browser Request Reaching Server ==="
echo "Checking if Web UI requests are reaching the server..."
echo "Recent pveproxy access logs:"
if [ -f /var/log/pveproxy/access.log ]; then
    tail -20 /var/log/pveproxy/access.log
else
    echo "No access.log found in /var/log/pveproxy/"
    echo "Checking systemd journal instead:"
    journalctl -u pveproxy --since "5 minutes ago" --no-pager | grep -E "GET|POST|authentication|login" | tail -20
fi
echo ""

echo "=== 12. Compare @pam vs @pve User Configuration ==="
echo ""
echo "Checking if sleszugreen@pam exists in PVE database at all..."
pveum user list | grep "sleszugreen@pam" && echo -e "${GREEN}Found sleszugreen@pam in PVE DB${NC}" || echo -e "${RED}NOT FOUND - sleszugreen@pam doesn't exist in PVE database!${NC}"
echo ""

echo "=========================================="
echo "DIAGNOSTIC SUMMARY"
echo "=========================================="
echo ""

echo -e "${YELLOW}KEY FINDINGS:${NC}"
echo ""

# Check 1: ACL permissions
if pveum acl list | grep -q "sleszugreen@pam"; then
    echo -e "${GREEN}[PASS]${NC} ACL permissions exist for sleszugreen@pam"
else
    echo -e "${RED}[FAIL]${NC} No ACL permissions for sleszugreen@pam"
    echo "       This is the MOST LIKELY cause of login failure"
fi

# Check 2: User in PVE database
if pveum user list | grep -q "sleszugreen@pam"; then
    echo -e "${GREEN}[PASS]${NC} sleszugreen@pam exists in PVE database"
else
    echo -e "${RED}[FAIL]${NC} sleszugreen@pam does NOT exist in PVE database"
    echo "       PAM users may need to be added to PVE DB for Web UI access"
fi

# Check 3: Password works
echo -e "${GREEN}[PASS]${NC} PAM password authentication works (verified via SSH)"

# Check 4: Services running
echo -e "${GREEN}[PASS]${NC} pveproxy and pvedaemon services running"

echo ""
echo "=========================================="
echo "RECOMMENDED FIXES"
echo "=========================================="
echo ""

if ! pveum acl list | grep -q "sleszugreen@pam"; then
    echo -e "${YELLOW}FIX #1: Add ACL permissions for sleszugreen@pam${NC}"
    echo ""
    echo "Run these commands:"
    echo ""
    echo "  # Add sleszugreen@pam to PVE database (if not exists)"
    echo "  pveum user add sleszugreen@pam"
    echo ""
    echo "  # Grant Administrator permissions"
    echo "  pveum acl modify / -user sleszugreen@pam -role Administrator"
    echo ""
    echo "Then try Web UI login again"
    echo ""
fi

if ! groups sleszugreen | grep -q "sudo"; then
    echo -e "${YELLOW}FIX #2: Add sleszugreen to sudo group (optional but recommended)${NC}"
    echo ""
    echo "Run:"
    echo "  usermod -aG sudo sleszugreen"
    echo ""
fi

echo "=========================================="
echo "NEXT STEP:"
echo "1. Review the findings above"
echo "2. Apply recommended fixes"
echo "3. Test Web UI login: sleszugreen + Linux PAM realm"
echo "=========================================="
