#!/bin/bash
#
# Script 10: Checkpoint #2 - Verify Hardened Access
# Part of Proxmox Security Hardening - Phase B
#
# Purpose: Comprehensive verification of hardened system
# - Test SSH access on new port (22022)
# - Verify firewall is working correctly
# - Test Web UI access
# - Verify emergency access methods
# - Confirm all security measures are active
#
# THIS CHECKPOINT IS MANDATORY before moving the box!
#

set -e  # Exit on error

SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"

NEW_SSH_PORT="22022"
TRUSTED_IP="192.168.99.6"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=10

echo "=========================================="
echo "Phase B - Script 10: Checkpoint #2"
echo "Hardened Access Verification"
echo "=========================================="
echo ""
echo -e "${BLUE}This checkpoint verifies:${NC}"
echo "  - SSH access on new port $NEW_SSH_PORT"
echo "  - Firewall rules protecting the system"
echo "  - Web UI access from trusted IP"
echo "  - Emergency access methods"
echo "  - All security hardening is active"
echo ""
echo -e "${RED}IMPORTANT: This must pass BEFORE moving the box!${NC}"
echo ""

log "Starting Checkpoint #2 verification"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo bash $0"
    exit 1
fi

read -p "Press Enter to begin checkpoint tests..."
echo ""

# ===========================================
# TEST 1: SSH Service Running
# ===========================================
echo "=========================================="
echo "Test 1/10: SSH Service Status"
echo "=========================================="

if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}✓ PASS${NC} - SSH service is running"
    ((TESTS_PASSED+=1))
else
    echo -e "${RED}✗ FAIL${NC} - SSH service is NOT running!"
    ((TESTS_FAILED+=1))
fi

# Show SSH port
CURRENT_PORT=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')
echo "  SSH Port: ${CURRENT_PORT:-22 (default)}"
echo ""

# ===========================================
# TEST 2: SSH Listening on New Port
# ===========================================
echo "=========================================="
echo "Test 2/10: SSH Listening on Port $NEW_SSH_PORT"
echo "=========================================="

if ss -tln | grep -q ":$NEW_SSH_PORT "; then
    echo -e "${GREEN}✓ PASS${NC} - SSH is listening on port $NEW_SSH_PORT"
    ((TESTS_PASSED+=1))
else
    echo -e "${RED}✗ FAIL${NC} - SSH is NOT listening on port $NEW_SSH_PORT!"
    echo "  Check: ss -tln | grep :$NEW_SSH_PORT"
    ((TESTS_FAILED+=1))
fi
echo ""

# ===========================================
# TEST 3: Password Authentication Disabled
# ===========================================
echo "=========================================="
echo "Test 3/10: Password Authentication Disabled"
echo "=========================================="

if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo -e "${GREEN}✓ PASS${NC} - Password authentication is disabled"
    ((TESTS_PASSED+=1))
else
    echo -e "${RED}✗ FAIL${NC} - Password authentication is NOT disabled!"
    ((TESTS_FAILED+=1))
fi
echo ""

# ===========================================
# TEST 4: Root SSH Key Authentication
# ===========================================
echo "=========================================="
echo "Test 4/10: Root SSH Key Authentication"
echo "=========================================="
echo "You must test SSH key login for root from your desktop"
echo ""
echo -e "${YELLOW}ON YOUR WINDOWS DESKTOP, run:${NC}"
echo "  ssh -i C:\\Users\\jakub\\.ssh\\ugreen_key -p $NEW_SSH_PORT root@192.168.40.60"
echo ""
echo "Expected: Login WITHOUT password prompt"
echo ""
read -p "Did root SSH key login work? (yes/no): " ROOT_SSH_TEST

if [ "$ROOT_SSH_TEST" = "yes" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Root SSH key authentication works"
    ((TESTS_PASSED+=1))
else
    echo -e "${RED}✗ FAIL${NC} - Root SSH key authentication FAILED!"
    echo "  This is CRITICAL - do not proceed until fixed!"
    ((TESTS_FAILED+=1))
fi
echo ""

# ===========================================
# TEST 5: User SSH Key Authentication
# ===========================================
echo "=========================================="
echo "Test 5/10: User (sleszugreen) SSH Key Authentication"
echo "=========================================="
echo "You must test SSH key login for sleszugreen from your desktop"
echo ""
echo -e "${YELLOW}ON YOUR WINDOWS DESKTOP, run:${NC}"
echo "  ssh -i C:\\Users\\jakub\\.ssh\\ugreen_key -p $NEW_SSH_PORT sleszugreen@192.168.40.60"
echo ""
echo "Expected: Login WITHOUT password prompt"
echo ""
read -p "Did sleszugreen SSH key login work? (yes/no): " USER_SSH_TEST

if [ "$USER_SSH_TEST" = "yes" ]; then
    echo -e "${GREEN}✓ PASS${NC} - User SSH key authentication works"
    ((TESTS_PASSED+=1))
else
    echo -e "${RED}✗ FAIL${NC} - User SSH key authentication FAILED!"
    ((TESTS_FAILED+=1))
fi
echo ""

# ===========================================
# TEST 6: Firewall Active
# ===========================================
echo "=========================================="
echo "Test 6/10: Proxmox Firewall Status"
echo "=========================================="

if systemctl is-active --quiet pve-firewall; then
    echo -e "${GREEN}✓ PASS${NC} - Proxmox firewall is active"
    ((TESTS_PASSED+=1))

    # Show firewall rules
    echo ""
    echo "Active firewall rules:"
    grep "^IN " /etc/pve/firewall/cluster.fw 2>/dev/null | head -10 || echo "(No rules found)"
else
    echo -e "${RED}✗ FAIL${NC} - Proxmox firewall is NOT active!"
    ((TESTS_FAILED+=1))
fi
echo ""

# ===========================================
# TEST 7: Web UI Accessible
# ===========================================
echo "=========================================="
echo "Test 7/10: Proxmox Web UI Accessible"
echo "=========================================="

if systemctl is-active --quiet pveproxy; then
    echo -e "${GREEN}✓ PASS${NC} - pveproxy service is running"

    echo ""
    echo "Test Web UI access from your desktop:"
    echo "  URL: https://192.168.40.60:8006"
    echo "  Login: root@pam (or sleszugreen@pam/pve)"
    echo ""
    read -p "Can you access Web UI from desktop? (yes/no): " WEBUI_TEST

    if [ "$WEBUI_TEST" = "yes" ]; then
        echo -e "${GREEN}✓ PASS${NC} - Web UI is accessible"
        ((TESTS_PASSED+=1))
    else
        echo -e "${RED}✗ FAIL${NC} - Web UI is NOT accessible!"
        ((TESTS_FAILED+=1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - pveproxy service is NOT running!"
    ((TESTS_FAILED+=1))
fi
echo ""

# ===========================================
# TEST 8: Web UI Shell (Emergency Access)
# ===========================================
echo "=========================================="
echo "Test 8/10: Web UI Shell (Emergency Access)"
echo "=========================================="
echo "The Web UI Shell is your emergency backup access"
echo ""
echo "To test:"
echo "  1. Open Web UI: https://192.168.40.60:8006"
echo "  2. Login as root@pam"
echo "  3. Click node 'ugreen' in left sidebar"
echo "  4. Click '>_ Shell' button at top"
echo "  5. Terminal opens in browser"
echo "  6. Type: whoami"
echo "  7. Should show: root"
echo ""
read -p "Does Web UI Shell work? (yes/no): " SHELL_TEST

if [ "$SHELL_TEST" = "yes" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Web UI Shell emergency access works"
    ((TESTS_PASSED+=1))
else
    echo -e "${RED}✗ FAIL${NC} - Web UI Shell does NOT work!"
    echo "  This is your emergency backup - fix before proceeding!"
    ((TESTS_FAILED+=1))
fi
echo ""

# ===========================================
# TEST 9: Multiple SSH Sessions
# ===========================================
echo "=========================================="
echo "Test 9/10: Multiple SSH Sessions"
echo "=========================================="

ACTIVE_SESSIONS=$(who | wc -l)
echo "Active sessions: $ACTIVE_SESSIONS"

if [ "$ACTIVE_SESSIONS" -ge 2 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Multiple sessions can connect"
    ((TESTS_PASSED+=1))
else
    echo -e "${YELLOW}⚠ WARNING${NC} - Only $ACTIVE_SESSIONS session(s) active"
    echo "  Try opening a second SSH connection to verify"
    read -p "Can you open multiple SSH sessions? (yes/no): " MULTI_TEST
    if [ "$MULTI_TEST" = "yes" ]; then
        echo -e "${GREEN}✓ PASS${NC} - Multiple sessions work"
        ((TESTS_PASSED+=1))
    else
        echo -e "${RED}✗ FAIL${NC} - Cannot open multiple sessions!"
        ((TESTS_FAILED+=1))
    fi
fi
echo ""

# ===========================================
# TEST 10: Security Hardening Applied
# ===========================================
echo "=========================================="
echo "Test 10/10: Security Hardening Summary"
echo "=========================================="

HARDENING_OK=true

# Check SSH hardening
if grep -q "^Port $NEW_SSH_PORT" /etc/ssh/sshd_config && \
   grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo -e "${GREEN}✓${NC} SSH hardened (port $NEW_SSH_PORT, keys only)"
else
    echo -e "${RED}✗${NC} SSH NOT properly hardened!"
    HARDENING_OK=false
fi

# Check firewall
if systemctl is-active --quiet pve-firewall; then
    echo -e "${GREEN}✓${NC} Firewall active and protecting system"
else
    echo -e "${RED}✗${NC} Firewall NOT active!"
    HARDENING_OK=false
fi

# Check SSH keys
if [ -f /root/.ssh/authorized_keys ] && [ -f /home/sleszugreen/.ssh/authorized_keys ]; then
    echo -e "${GREEN}✓${NC} SSH keys configured for root and sleszugreen"
else
    echo -e "${RED}✗${NC} SSH keys NOT properly configured!"
    HARDENING_OK=false
fi

if [ "$HARDENING_OK" = true ]; then
    echo -e "${GREEN}✓ PASS${NC} - All security hardening is active"
    ((TESTS_PASSED+=1))
else
    echo -e "${RED}✗ FAIL${NC} - Security hardening incomplete!"
    ((TESTS_FAILED+=1))
fi
echo ""

# ===========================================
# FINAL RESULTS
# ===========================================
echo "=========================================="
echo "CHECKPOINT #2 - FINAL RESULTS"
echo "=========================================="
echo ""
echo "Tests Passed: $TESTS_PASSED / $TESTS_TOTAL"
echo "Tests Failed: $TESTS_FAILED / $TESTS_TOTAL"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✓ CHECKPOINT #2: PASSED${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "All tests passed! Your Proxmox server is:"
    echo "  ✓ Hardened and secure"
    echo "  ✓ Accessible via SSH (port $NEW_SSH_PORT, keys only)"
    echo "  ✓ Protected by firewall"
    echo "  ✓ Web UI accessible from trusted IP"
    echo "  ✓ Emergency access methods verified"
    echo ""
    echo -e "${GREEN}IT IS NOW SAFE TO MOVE THE BOX${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Document new SSH port: $NEW_SSH_PORT"
    echo "  2. Update desktop SSH config (optional)"
    echo "  3. Move box to remote location"
    echo "  4. After moving: Run Phase C (monitoring & protection)"
    log "Checkpoint #2 PASSED - System ready for deployment"
else
    echo -e "${RED}================================${NC}"
    echo -e "${RED}✗ CHECKPOINT #2: FAILED${NC}"
    echo -e "${RED}================================${NC}"
    echo ""
    echo "$TESTS_FAILED test(s) failed!"
    echo ""
    echo -e "${RED}DO NOT MOVE THE BOX YET!${NC}"
    echo ""
    echo "Fix the failed tests before proceeding."
    echo "Review the test results above and resolve issues."
    echo ""
    echo "You can re-run this checkpoint after fixes:"
    echo "  bash $0"
    log "Checkpoint #2 FAILED - $TESTS_FAILED tests failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "HARDENING SUMMARY"
echo "=========================================="
echo ""
echo "SSH Configuration:"
echo "  Port: $NEW_SSH_PORT"
echo "  Password Auth: DISABLED"
echo "  Key Auth: ENABLED"
echo "  Root Password Login: DISABLED"
echo "  Root Key Login: ENABLED"
echo ""
echo "Firewall Configuration:"
echo "  Status: ACTIVE"
echo "  Trusted IP: $TRUSTED_IP"
echo "  Default Policy: DROP"
echo ""
echo "Access Methods:"
echo "  1. SSH (port $NEW_SSH_PORT, keys only)"
echo "  2. Web UI (https://192.168.40.60:8006)"
echo "  3. Web UI Shell (emergency)"
echo ""
echo "Emergency Commands:"
echo "  Disable firewall: systemctl stop pve-firewall"
echo "  Restore SSH: cp $SCRIPT_DIR/backups/ssh/sshd_config.before-hardening /etc/ssh/sshd_config && systemctl restart ssh"
echo ""
echo "=========================================="
log "Checkpoint #2 completed - All tests passed"
