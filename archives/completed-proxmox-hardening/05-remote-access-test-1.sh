#!/bin/bash
#########################################################################
# Proxmox Hardening - Phase A Script 5
# Remote Access Test #1 (MANDATORY CHECKPOINT)
#
# Purpose: Verify all remote access methods work before proceeding
#          to Phase B security hardening
#
# Run as: sudo bash 05-remote-access-test-1.sh
#########################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging
SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"

mkdir -p "$SCRIPT_DIR"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

failed() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   echo "Please run: sudo bash $0"
   exit 1
fi

# Get system info
IP_ADDRESS=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
REAL_USER=${SUDO_USER:-sleszugreen}

section "Remote Access Test - Checkpoint #1"

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                  ⚠️  MANDATORY CHECKPOINT #1  ⚠️                    ║
║                                                                    ║
║              VERIFY REMOTE ACCESS BEFORE PROCEEDING                ║
║                                                                    ║
║  DO NOT CONTINUE TO PHASE B UNTIL ALL TESTS PASS!                 ║
╚════════════════════════════════════════════════════════════════════╝

This checkpoint verifies that you have multiple ways to access your
Proxmox server. If anything goes wrong during Phase B hardening, you
need these backup access methods!

Phase B will:
  • Change SSH port to 22022
  • Disable password authentication
  • Enable strict firewall rules
  • Disable root SSH login

IF YOU GET LOCKED OUT, you need backup access methods!

EOF

log "Starting remote access verification..."
log "System: $HOSTNAME ($IP_ADDRESS)"
log "User: $REAL_USER"
echo ""

# Test checklist
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=7

# Test 1: SSH Key Authentication
section "Test 1: SSH Key Authentication"

cat << EOF
${BOLD}Verify SSH key authentication works:${NC}

On your desktop (192.168.99.6), open a NEW terminal and run:

    ssh $REAL_USER@$IP_ADDRESS

Expected behavior:
  ✓ Login succeeds without password (or only key passphrase if you set one)
  ✓ You get a shell prompt
  ✓ You can run commands

EOF

read -p "Does SSH key authentication work? (yes/no): " ssh_key_test

if [[ "$ssh_key_test" == "yes" ]]; then
    success "SSH key authentication working"
    ((TESTS_PASSED++))
else
    failed "SSH key authentication NOT working"
    ((TESTS_FAILED++))
    error "CRITICAL: Fix SSH keys before continuing!"
    echo "  Run: sudo bash 04-ssh-key-setup.sh"
fi

# Test 2: Multiple SSH Sessions
section "Test 2: Multiple SSH Sessions"

cat << 'EOF'
Verify you can have multiple SSH sessions open:

1. You should ALREADY have this session open
2. Open a SECOND SSH session from your desktop
3. Keep BOTH sessions open

This is critical for safety - if one session has issues, you have backup!

EOF

read -p "Do you have at least 2 SSH sessions open? (yes/no): " multi_ssh_test

if [[ "$multi_ssh_test" == "yes" ]]; then
    success "Multiple SSH sessions confirmed"
    ((TESTS_PASSED++))
else
    failed "Only one SSH session open"
    ((TESTS_FAILED++))
    warn "STRONGLY RECOMMENDED: Open another SSH session as backup"
fi

# Test 3: Proxmox Web UI Access
section "Test 3: Proxmox Web UI Access"

cat << EOF
Verify Proxmox Web UI is accessible:

Open a web browser on your desktop and go to:

    https://$IP_ADDRESS:8006

Expected behavior:
  ✓ Page loads (may show SSL warning - this is normal)
  ✓ You can login with username: $REAL_USER
  ✓ Dashboard displays correctly

EOF

read -p "Can you access Proxmox Web UI? (yes/no): " webui_test

if [[ "$webui_test" == "yes" ]]; then
    success "Proxmox Web UI accessible"
    ((TESTS_PASSED++))
else
    failed "Proxmox Web UI NOT accessible"
    ((TESTS_FAILED++))
    error "CRITICAL: Web UI must work as backup access!"
fi

# Test 4: Web UI Shell Access
section "Test 4: Web UI Shell Access (EMERGENCY BACKUP)"

cat << EOF
${BOLD}${MAGENTA}THIS IS YOUR EMERGENCY BACKUP ACCESS!${NC}

Verify Web UI Shell works:

1. In the Proxmox Web UI, look at left sidebar
2. Click on "$HOSTNAME" (the node name)
3. Click the "Shell" button at the top (looks like >_)
4. A terminal should open in your browser
5. Try typing: whoami
6. Try: sudo -l

Expected behavior:
  ✓ Shell terminal opens in browser
  ✓ You can type commands
  ✓ Commands execute and show output
  ✓ You can use sudo

${RED}THIS IS CRITICAL! If SSH fails, this is your backup!${NC}

EOF

read -p "Does Web UI Shell work? (yes/no): " webshell_test

if [[ "$webshell_test" == "yes" ]]; then
    success "Web UI Shell working (EMERGENCY ACCESS VERIFIED)"
    ((TESTS_PASSED++))
else
    failed "Web UI Shell NOT working"
    ((TESTS_FAILED++))
    error "CRITICAL: This is your emergency backup access!"
    error "DO NOT PROCEED until this works!"
fi

# Test 5: Sudo Access
section "Test 5: Sudo Access"

cat << EOF
Verify sudo access works:

In one of your SSH sessions, run:

    sudo whoami

Expected output: root

EOF

# Test it locally
if sudo -n true 2>/dev/null; then
    success "Sudo access working (passwordless)"
    ((TESTS_PASSED++))
elif sudo -l &>/dev/null; then
    success "Sudo access working (password required)"
    ((TESTS_PASSED++))
else
    failed "Sudo access issue detected"
    ((TESTS_FAILED++))
    warn "Check sudo configuration for user $REAL_USER"
fi

# Test 6: Network Connectivity
section "Test 6: Network Connectivity"

info "Testing network connectivity..."

if ping -c 2 8.8.8.8 &>/dev/null; then
    success "Internet connectivity working"
    ((TESTS_PASSED++))
else
    failed "Internet connectivity issue"
    ((TESTS_FAILED++))
    warn "Some features may not work without internet"
fi

# Test 7: Emergency Access Awareness
section "Test 7: Emergency Access Awareness"

cat << 'EOF'
If you get locked out of SSH, you can access via:

1. PROXMOX WEB UI SHELL (Primary backup)
   • https://192.168.40.60:8006
   • Login → Click node → Click "Shell"
   • Full terminal access in browser

2. PHYSICAL CONSOLE (Ultimate fallback)
   • Connect monitor and keyboard
   • Login at console
   • Run emergency rollback script

3. EMERGENCY ROLLBACK SCRIPT
   • /root/proxmox-hardening/99-emergency-rollback.sh
   • Restores all configs to pre-hardening state

EOF

read -p "Do you understand the emergency access methods? (yes/no): " emergency_understanding

if [[ "$emergency_understanding" == "yes" ]]; then
    success "Emergency access methods understood"
    ((TESTS_PASSED++))
else
    warn "Please review emergency access methods above"
    ((TESTS_FAILED++))
fi

# Display test results
section "Checkpoint #1 Results"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo -e "  Tests Passed: ${GREEN}$TESTS_PASSED${NC} / $TOTAL_TESTS"
echo -e "  Tests Failed: ${RED}$TESTS_FAILED${NC} / $TOTAL_TESTS"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Determine pass/fail
CRITICAL_TESTS_PASSED=true

if [[ "$ssh_key_test" != "yes" ]]; then
    CRITICAL_TESTS_PASSED=false
fi

if [[ "$webui_test" != "yes" ]]; then
    CRITICAL_TESTS_PASSED=false
fi

if [[ "$webshell_test" != "yes" ]]; then
    CRITICAL_TESTS_PASSED=false
fi

# Final verdict
section "Checkpoint Status"

if [[ "$CRITICAL_TESTS_PASSED" == "true" ]]; then
    echo ""
    success "═══════════════════════════════════════════════════════════════"
    success "        CHECKPOINT #1 PASSED - READY FOR PHASE B              "
    success "═══════════════════════════════════════════════════════════════"
    echo ""
    log "✓ All critical remote access tests passed"
    log "✓ Safe to proceed to Phase B (Security Hardening)"
    echo ""

    info "Phase B will harden security:"
    echo "  • Install security tools and updates"
    echo "  • Configure firewall (whitelist 192.168.99.6)"
    echo "  • Set up HTTPS certificate"
    echo "  • Harden SSH (port 22022, keys-only)"
    echo ""

    log "Next steps:"
    echo "  1. Review Phase B scripts in $SCRIPT_DIR/"
    echo "  2. Run scripts 06-11 (Phase B)"
    echo "  3. Complete Checkpoint #2 before moving box"
    echo ""

    info "Start Phase B with: sudo bash 06-system-update.sh"
    echo ""

    log "Checkpoint #1 completed successfully!" | tee -a "$LOG_FILE"
    exit 0
else
    echo ""
    failed "═══════════════════════════════════════════════════════════════"
    failed "        CHECKPOINT #1 FAILED - DO NOT PROCEED!                 "
    failed "═══════════════════════════════════════════════════════════════"
    echo ""
    error "Critical tests failed! You MUST fix these issues before Phase B"
    echo ""

    if [[ "$ssh_key_test" != "yes" ]]; then
        error "✗ SSH key authentication not working"
        echo "  Fix: sudo bash 04-ssh-key-setup.sh"
    fi

    if [[ "$webui_test" != "yes" ]]; then
        error "✗ Proxmox Web UI not accessible"
        echo "  Check: https://$IP_ADDRESS:8006"
        echo "  Verify: Network connection, firewall, pveproxy service"
    fi

    if [[ "$webshell_test" != "yes" ]]; then
        error "✗ Web UI Shell not working"
        echo "  This is your emergency backup access!"
        echo "  Test again: Web UI → Click node → Click Shell button"
    fi

    echo ""
    error "DO NOT PROCEED TO PHASE B UNTIL ALL CRITICAL TESTS PASS!"
    error "Re-run this script after fixing issues: sudo bash $0"
    echo ""

    log "Checkpoint #1 FAILED - Issues must be resolved" | tee -a "$LOG_FILE"
    exit 1
fi
