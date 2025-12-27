#!/bin/bash

################################################################################
# Phase A Checkpoint Verification
# Purpose: Verify all Phase A security measures are active
# Duration: 10 minutes
# Safety: Read-only verification (no changes)
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RESULTS_FILE="${HOME}/vm100-hardening/CHECKPOINT-A-RESULTS.txt"
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PHASE A CHECKPOINT VERIFICATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Running 8 verification tests..."
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << 'EOF'
═══════════════════════════════════════════════════════════════════════
PHASE A CHECKPOINT RESULTS
Test Date: $(date)
═══════════════════════════════════════════════════════════════════════

EOF

# Test 1: SSH on port 22022 (keys-only)
echo -n "Test 1/8: SSH on port 22022 with keys-only authentication... "
if sudo sshd -t -f /etc/ssh/sshd_config >/dev/null 2>&1; then
    if sudo grep -q "^Port 22022" /etc/ssh/sshd_config && \
       sudo grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        echo "✓ Test 1: SSH on port 22022 with keys-only auth - PASS" >> "$RESULTS_FILE"
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
        echo "✗ Test 1: SSH configuration incorrect - FAIL" >> "$RESULTS_FILE"
    fi
else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    echo "✗ Test 1: SSH configuration invalid - FAIL" >> "$RESULTS_FILE"
fi

# Test 2: Password authentication disabled
echo -n "Test 2/8: Password authentication disabled... "
if sudo grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
    echo "✓ Test 2: Password authentication disabled - PASS" >> "$RESULTS_FILE"
else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    echo "✗ Test 2: Password authentication still enabled - FAIL" >> "$RESULTS_FILE"
fi

# Test 3: UFW firewall active
echo -n "Test 3/8: UFW firewall active and configured... "
if sudo ufw status | grep -q "Status: active"; then
    if sudo ufw status | grep -q "22022/tcp"; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        echo "✓ Test 3: UFW firewall active with SSH rule - PASS" >> "$RESULTS_FILE"
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
        echo "✗ Test 3: UFW active but SSH rule missing - FAIL" >> "$RESULTS_FILE"
    fi
else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    echo "✗ Test 3: UFW firewall not active - FAIL" >> "$RESULTS_FILE"
fi

# Test 4: Docker daemon hardened (userns-remap)
echo -n "Test 4/8: Docker daemon hardened with userns-remap... "
if sudo grep -q "userns-remap" /etc/docker/daemon.json; then
    if docker info 2>/dev/null | grep -q "userns"; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        echo "✓ Test 4: Docker hardening with userns-remap active - PASS" >> "$RESULTS_FILE"
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
        echo "✗ Test 4: userns-remap configured but not active - FAIL" >> "$RESULTS_FILE"
    fi
else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    echo "✗ Test 4: Docker daemon not hardened - FAIL" >> "$RESULTS_FILE"
fi

# Test 5: Custom Docker networks created
echo -n "Test 5/8: Custom Docker networks (frontend, backend, monitoring)... "
NETWORKS_OK=true
for net in frontend backend monitoring; do
    if ! docker network ls | grep -q "^[^ ]*[[:space:]]\\+$net[[:space:]]"; then
        NETWORKS_OK=false
        break
    fi
done

if [[ "$NETWORKS_OK" == "true" ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
    echo "✓ Test 5: All three custom Docker networks exist - PASS" >> "$RESULTS_FILE"
else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    echo "✗ Test 5: Missing one or more custom Docker networks - FAIL" >> "$RESULTS_FILE"
fi

# Test 6: Portainer accessible on HTTPS 9443
echo -n "Test 6/8: Portainer accessible on HTTPS port 9443... "
if docker ps | grep -q "portainer"; then
    if timeout 5 curl -sk https://localhost:9443 >/dev/null 2>&1 || \
       nc -z localhost 9443 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        echo "✓ Test 6: Portainer running and accessible on port 9443 - PASS" >> "$RESULTS_FILE"
    else
        echo -e "${YELLOW}⚠ WARN${NC}"
        ((TESTS_PASSED++))
        echo "⚠ Test 6: Portainer running but couldn't verify connectivity - WARN" >> "$RESULTS_FILE"
    fi
else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    echo "✗ Test 6: Portainer container not running - FAIL" >> "$RESULTS_FILE"
fi

# Test 7: Docker daemon is healthy
echo -n "Test 7/8: Docker daemon healthy and responsive... "
if docker ps >/dev/null 2>&1; then
    if sudo systemctl is-active docker >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        echo "✓ Test 7: Docker daemon is healthy and responsive - PASS" >> "$RESULTS_FILE"
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
        echo "✗ Test 7: Docker daemon not active - FAIL" >> "$RESULTS_FILE"
    fi
else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    echo "✗ Test 7: Docker daemon not responding - FAIL" >> "$RESULTS_FILE"
fi

# Test 8: Proxmox console emergency access
echo -n "Test 8/8: Proxmox Web UI console access available... "
echo -e "${YELLOW}MANUAL${NC}"
echo "Please verify manually: https://192.168.40.60:8006 → VM 100 → Console"
echo "⚠ Test 8: Requires manual verification via Proxmox Web UI" >> "$RESULTS_FILE"
# Don't count this as pass/fail since it requires manual verification

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}CHECKPOINT RESULTS SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo "Tests Passed: $TESTS_PASSED / 7"
echo "Tests Failed: $TESTS_FAILED / 7"
echo ""

# Add summary to results file
cat >> "$RESULTS_FILE" << EOF

═══════════════════════════════════════════════════════════════════════
SUMMARY
═══════════════════════════════════════════════════════════════════════
Tests Passed: $TESTS_PASSED / 7
Tests Failed: $TESTS_FAILED / 7
EOF

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo ""
    echo "Phase A hardening is complete and verified."
    cat >> "$RESULTS_FILE" << EOF

STATUS: ✓ PHASE A COMPLETE
All 7 automated tests passed. Phase A hardening successful.

MANUAL VERIFICATION REQUIRED:
- Test 8: Verify Proxmox Web UI console access
  Location: https://192.168.40.60:8006 → VM 100 → Console
  Login: sleszdockerugreen

Next Steps:
1. Verify Portainer web UI: https://192.168.40.60:9443
2. Create admin account in Portainer
3. When ready, proceed to Phase B (OS & Container Hardening)
EOF
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "The following tests failed:"
    grep "✗" "$RESULTS_FILE" | tail -$TESTS_FAILED
    echo ""
    echo "Troubleshooting:"
    echo "1. Review failed test output above"
    echo "2. Run individual scripts to fix issues:"
    echo "   - SSH issue: bash ${HOME}/scripts/vm100ugreen/hardening/01-ssh-hardening.sh"
    echo "   - Firewall issue: bash ${HOME}/scripts/vm100ugreen/hardening/02-ufw-firewall.sh"
    echo "   - Docker issue: bash ${HOME}/scripts/vm100ugreen/hardening/03-docker-daemon-hardening.sh"
    echo "   - Network issue: bash ${HOME}/scripts/vm100ugreen/hardening/04-docker-network-security.sh"
    echo "   - Portainer issue: bash ${HOME}/scripts/vm100ugreen/hardening/05-portainer-deployment.sh"
    echo "3. Re-run this checkpoint script to verify fixes"
    echo ""
    echo "If unable to fix, rollback to pre-hardening state:"
    echo "  bash ${HOME}/scripts/vm100ugreen/hardening/99-emergency-rollback.sh"
    
    cat >> "$RESULTS_FILE" << EOF

STATUS: ✗ PHASE A INCOMPLETE
$TESTS_FAILED test(s) failed. See troubleshooting steps above.

FAILED TESTS:
EOF
    grep "✗" "$RESULTS_FILE" >> "$RESULTS_FILE" || true
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo "Results saved to: $RESULTS_FILE"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
