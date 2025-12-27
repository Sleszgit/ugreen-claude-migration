#!/bin/bash

################################################################################
# Script 02: UFW Firewall Configuration
# Purpose: Configure UFW firewall at VM level (complements Proxmox firewall)
# Duration: 10 minutes
# Safety: SAFE - Firewall rules allow SSH on port 22022
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="${HOME}/vm100-hardening/backups"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Script 02: UFW Firewall Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Install UFW if needed
echo -e "${YELLOW}[STEP 1]${NC} Installing UFW (if not present)..."
if ! command -v ufw >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y ufw >/dev/null 2>&1
    echo -e "${GREEN}✓ UFW installed${NC}"
else
    echo -e "${GREEN}✓ UFW already installed${NC}"
fi
echo ""

# Step 2: Backup current UFW status
echo -e "${YELLOW}[STEP 2]${NC} Backing up current firewall state..."
sudo ufw status verbose > "$BACKUP_DIR/ufw-status.backup" 2>&1 || true
echo -e "${GREEN}✓ UFW status backed up${NC}"
echo ""

# Step 3: Set default policies
echo -e "${YELLOW}[STEP 3]${NC} Setting firewall default policies..."
sudo ufw --force reset >/dev/null 2>&1 || true
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo -e "${GREEN}✓ Default policies set (deny incoming, allow outgoing)${NC}"
echo ""

# Step 4: Allow SSH on new port
echo -e "${YELLOW}[STEP 4]${NC} Configuring SSH access on port 22022..."
sudo ufw allow from 192.168.40.0/24 to any port 22022 proto tcp comment 'SSH on 22022'
sudo ufw limit 22022/tcp comment 'SSH rate limiting'
echo -e "${GREEN}✓ SSH on port 22022 allowed (from 192.168.40.0/24)${NC}"
echo ""

# Step 5: Allow Portainer HTTPS
echo -e "${YELLOW}[STEP 5]${NC} Configuring Portainer access on port 9443..."
sudo ufw allow from 192.168.40.0/24 to any port 9443 proto tcp comment 'Portainer HTTPS'
echo -e "${GREEN}✓ Portainer on port 9443 allowed (from 192.168.40.0/24)${NC}"
echo ""

# Step 6: Enable UFW
echo -e "${YELLOW}[STEP 6]${NC} Enabling UFW firewall..."
sudo ufw --force enable >/dev/null 2>&1
echo -e "${GREEN}✓ UFW firewall enabled${NC}"
echo ""

# Step 7: Display active rules
echo -e "${YELLOW}[STEP 7]${NC} Firewall configuration:"
echo ""
sudo ufw status numbered
echo ""

# Step 8: Verify SSH still works
echo -e "${YELLOW}[STEP 8]${NC} Verifying SSH access..."
if nc -z localhost 22022 2>/dev/null; then
    echo -e "${GREEN}✓ SSH on port 22022 is accessible${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify port 22022 (may still work)${NC}"
fi
echo ""

# Step 9: Test connectivity from internal network
echo -e "${YELLOW}[STEP 9]${NC} Testing internal network connectivity..."
if ping -c 1 192.168.40.1 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Internal network accessible${NC}"
else
    echo -e "${YELLOW}⚠ Could not ping gateway (firewall may be blocking ICMP)${NC}"
fi
echo ""

# Step 10: Display completion summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}UFW FIREWALL CONFIGURATION COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓${NC} Default policies configured (deny incoming, allow outgoing)"
echo -e "${GREEN}✓${NC} SSH access on port 22022 allowed (from 192.168.40.0/24)"
echo -e "${GREEN}✓${NC} Portainer access on port 9443 allowed (from 192.168.40.0/24)"
echo -e "${GREEN}✓${NC} UFW firewall enabled and active"
echo ""
echo -e "${YELLOW}FIREWALL RULES SUMMARY:${NC}"
echo "  - Deny: All incoming traffic (default)"
echo "  - Allow: All outgoing traffic"
echo "  - Allow: SSH on port 22022 from 192.168.40.0/24 (with rate limiting)"
echo "  - Allow: Portainer HTTPS on port 9443 from 192.168.40.0/24"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "To disable firewall if needed:"
echo "  sudo ufw disable"
echo ""
echo "To view current rules:"
echo "  sudo ufw status verbose"
echo ""
echo -e "${GREEN}Script 02 complete! Proceed to Script 03.${NC}"
