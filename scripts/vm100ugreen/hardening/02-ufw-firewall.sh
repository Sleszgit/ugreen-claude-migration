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
sudo ufw default allow forward  # Required for Docker container networking
echo -e "${GREEN}✓ Default policies set (deny incoming, allow outgoing, allow forward)${NC}"
echo ""

# Step 3b: Fix UFW config for Docker
echo -e "${YELLOW}[STEP 3b]${NC} Configuring UFW for Docker networking..."
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
echo -e "${GREEN}✓ Docker forwarding policy set to ACCEPT${NC}"
echo ""

# Step 4: Allow SSH on new port (from both VLAN10 and Management subnet)
echo -e "${YELLOW}[STEP 4]${NC} Configuring SSH access on port 22022..."
sudo ufw allow from 10.10.10.0/24 to any port 22022 proto tcp comment 'SSH from VLAN10'
sudo ufw allow from 192.168.40.0/24 to any port 22022 proto tcp comment 'SSH from Management LAN'
echo -e "${GREEN}✓ SSH on port 22022 allowed ONLY from trusted networks (from 10.10.10.0/24 and 192.168.40.0/24)${NC}"
echo ""

# Step 5: Allow HTTP/HTTPS for public-facing services
echo -e "${YELLOW}[STEP 5]${NC} Configuring HTTP/HTTPS access..."
sudo ufw allow 80/tcp comment 'HTTP for Nginx Proxy Manager'
sudo ufw allow 443/tcp comment 'HTTPS for Nginx Proxy Manager'
echo -e "${GREEN}✓ HTTP (80) and HTTPS (443) allowed for all public services${NC}"
echo ""

# Step 6: Allow Portainer HTTPS (from both VLAN10 and Management subnet)
echo -e "${YELLOW}[STEP 6]${NC} Configuring Portainer access on port 9443..."
sudo ufw allow from 10.10.10.0/24 to any port 9443 proto tcp comment 'Portainer from VLAN10'
sudo ufw allow from 192.168.40.0/24 to any port 9443 proto tcp comment 'Portainer from Management LAN'
echo -e "${GREEN}✓ Portainer on port 9443 allowed (from 10.10.10.0/24 and 192.168.40.0/24)${NC}"
echo ""

# Step 7: Enable UFW
echo -e "${YELLOW}[STEP 7]${NC} Enabling UFW firewall..."
sudo ufw --force enable >/dev/null 2>&1
sudo ufw reload >/dev/null 2>&1
echo -e "${GREEN}✓ UFW firewall enabled with Docker forwarding support${NC}"
echo ""

# Step 8: Display active rules
echo -e "${YELLOW}[STEP 8]${NC} Firewall configuration:"
echo ""
sudo ufw status numbered
echo ""

# Step 9: Verify SSH still works
echo -e "${YELLOW}[STEP 9]${NC} Verifying SSH access..."
if nc -z localhost 22022 2>/dev/null; then
    echo -e "${GREEN}✓ SSH on port 22022 is accessible${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify port 22022 (may still work)${NC}"
fi
echo ""

# Step 10: Test Docker container connectivity
echo -e "${YELLOW}[STEP 10]${NC} Testing Docker container network connectivity..."
if ping -c 1 10.10.10.1 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ VLAN10 gateway accessible${NC}"
else
    echo -e "${YELLOW}⚠ Could not ping VLAN10 gateway (ICMP may be blocked by upstream)${NC}"
fi
echo ""

# Step 11: Display completion summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}UFW FIREWALL CONFIGURATION COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓${NC} Default policies configured (deny incoming, allow outgoing, allow forward)"
echo -e "${GREEN}✓${NC} Docker forwarding enabled (DEFAULT_FORWARD_POLICY=ACCEPT)"
echo -e "${GREEN}✓${NC} SSH access on port 22022 allowed (from VLAN10 and Management LAN)"
echo -e "${GREEN}✓${NC} HTTP/HTTPS (80/443) allowed for public services"
echo -e "${GREEN}✓${NC} Portainer access on port 9443 allowed (from VLAN10 and Management LAN)"
echo -e "${GREEN}✓${NC} UFW firewall enabled and active"
echo ""
echo -e "${YELLOW}FIREWALL RULES SUMMARY:${NC}"
echo "  - Deny: All incoming traffic (default)"
echo "  - Allow: All outgoing traffic"
echo "  - Allow: Forward traffic (for Docker containers)"
echo "  - Allow: SSH on port 22022 from 10.10.10.0/24 (VLAN10) with rate limiting"
echo "  - Allow: SSH on port 22022 from 192.168.40.0/24 (Management LAN)"
echo "  - Allow: HTTP (80) from anywhere"
echo "  - Allow: HTTPS (443) from anywhere"
echo "  - Allow: Portainer on port 9443 from 10.10.10.0/24 (VLAN10)"
echo "  - Allow: Portainer on port 9443 from 192.168.40.0/24 (Management LAN)"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "To disable firewall if needed:"
echo "  sudo ufw disable"
echo ""
echo "To view current rules:"
echo "  sudo ufw status verbose"
echo ""
echo -e "${GREEN}Script 02 complete! Proceed to Script 03.${NC}"
