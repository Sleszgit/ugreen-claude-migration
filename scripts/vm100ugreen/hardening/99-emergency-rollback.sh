#!/bin/bash

################################################################################
# Emergency Rollback Script
# Purpose: Restore pre-hardening state if anything goes wrong
# Safety: Restores from backups created by Script 00
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="${HOME}/vm100-hardening/backups"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}⚠️  EMERGENCY ROLLBACK${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${RED}WARNING: This will restore VM 100 to pre-hardening state${NC}"
echo ""
echo "Affected services:"
echo "  • SSH will restart (may interrupt your connection)"
echo "  • Docker daemon will restart (containers may be interrupted)"
echo "  • UFW firewall will be disabled"
echo ""
echo -e "${YELLOW}Continue? (type 'yes' to proceed)${NC}"
read -r CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Rollback cancelled."
    exit 0
fi

echo ""
echo "Starting rollback..."
echo ""

# Step 1: Restore SSH config
echo -e "${YELLOW}[1/3]${NC} Restoring SSH configuration..."
if [[ -f "$BACKUP_DIR/sshd_config.backup" ]]; then
    sudo cp "$BACKUP_DIR/sshd_config.backup" /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo -e "${GREEN}✓ SSH configuration restored${NC}"
else
    echo -e "${YELLOW}⚠ SSH backup not found (may have been lost)${NC}"
fi
echo ""

# Step 2: Restore Docker config
echo -e "${YELLOW}[2/3]${NC} Restoring Docker configuration..."
if [[ -f "$BACKUP_DIR/daemon.json.backup" ]]; then
    sudo cp "$BACKUP_DIR/daemon.json.backup" /etc/docker/daemon.json
    sudo systemctl restart docker
    
    # Wait for Docker to be ready
    for i in {1..15}; do
        if docker ps >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker configuration restored${NC}"
            break
        fi
        sleep 1
    done
else
    echo -e "${YELLOW}⚠ Docker backup not found (may have been lost)${NC}"
fi
echo ""

# Step 3: Disable UFW
echo -e "${YELLOW}[3/3]${NC} Disabling UFW firewall..."
if command -v ufw >/dev/null 2>&1; then
    sudo ufw disable >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ UFW firewall disabled${NC}"
else
    echo -e "${YELLOW}⚠ UFW not installed (nothing to disable)${NC}"
fi
echo ""

# Final status
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}ROLLBACK COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "VM 100 has been restored to pre-hardening state:"
echo -e "${GREEN}✓${NC} SSH on port 22 with password authentication"
echo -e "${GREEN}✓${NC} Docker daemon with default configuration"
echo -e "${GREEN}✓${NC} UFW firewall disabled"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "1. Log back in with the original SSH method:"
echo "   ssh sleszugreen@10.10.10.100"
echo ""
echo "2. Review what went wrong"
echo "3. Fix the issue and re-run affected scripts"
echo "4. Or contact support if you need help"
echo ""
echo -e "${YELLOW}To see Phase A checkpoint results:${NC}"
echo "   cat ${HOME}/vm100-hardening/CHECKPOINT-A-RESULTS.txt"
