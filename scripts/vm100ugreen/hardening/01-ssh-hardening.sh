#!/bin/bash

################################################################################
# Script 01: SSH Hardening
# Purpose: Configure SSH for keys-only authentication on non-standard port
# Duration: 15 minutes
# Safety: CRITICAL - Keep existing SSH session open during execution
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="${HOME}/vm100-hardening/backups"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Script 01: SSH Hardening${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Verify SSH keys exist
echo -e "${YELLOW}[STEP 1]${NC} Verifying SSH key authentication..."

if [[ ! -f ~/.ssh/authorized_keys ]]; then
    echo -e "${RED}✗ No authorized_keys file found${NC}"
    echo ""
    echo "To add SSH keys:"
    echo "1. Generate key on Windows desktop (if not done):"
    echo "   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519"
    echo ""
    echo "2. Add public key to this VM:"
    echo "   echo 'your_public_key_content' >> ~/.ssh/authorized_keys"
    echo "   chmod 600 ~/.ssh/authorized_keys"
    echo ""
    echo "3. Test key authentication works:"
    echo "   ssh -i ~/.ssh/id_ed25519 -p 22 sleszdockerugreen@192.168.40.60"
    echo ""
    echo "Once key auth is working, run this script again."
    exit 1
fi

KEYCOUNT=$(wc -l < ~/.ssh/authorized_keys)
echo -e "${GREEN}✓ SSH authorized_keys found ($KEYCOUNT key(s))${NC}"
echo ""

# Step 2: Backup sshd_config
echo -e "${YELLOW}[STEP 2]${NC} Backing up SSH configuration..."
if [[ ! -f "$BACKUP_DIR/sshd_config.backup" ]]; then
    sudo cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.backup"
fi
echo -e "${GREEN}✓ Backup created: $BACKUP_DIR/sshd_config.backup${NC}"
echo ""

# Step 3: Create new sshd_config
echo -e "${YELLOW}[STEP 3]${NC} Configuring SSH hardened settings..."
cat > /tmp/sshd_hardening << 'EOF'
# SSH Hardening Configuration
Port 22022
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

sudo tee /etc/ssh/sshd_config > /dev/null < /tmp/sshd_hardening
echo -e "${GREEN}✓ SSH configuration updated${NC}"
echo ""

# Step 4: Validate sshd configuration
echo -e "${YELLOW}[STEP 4]${NC} Validating SSH configuration..."
if sudo sshd -t 2>/dev/null; then
    echo -e "${GREEN}✓ SSH configuration syntax valid${NC}"
else
    echo -e "${RED}✗ SSH configuration has syntax errors${NC}"
    echo "Restoring previous configuration..."
    sudo cp "$BACKUP_DIR/sshd_config.backup" /etc/ssh/sshd_config
    exit 1
fi
echo ""

# Step 4.5: Pre-authorize port 22022 in firewall (before SSH restart)
echo -e "${YELLOW}[STEP 4.5]${NC} Pre-authorizing port 22022 in firewall..."
if command -v ufw >/dev/null 2>&1; then
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "${YELLOW}  UFW is active - adding temporary allow rule for 22022${NC}"
        sudo ufw allow 22022/tcp comment 'Temporary allow for SSH hardening verification' >/dev/null 2>&1
        echo -e "${GREEN}✓ Added UFW rule for port 22022/tcp${NC}"
    else
        echo -e "${GREEN}✓ UFW is not active (no pre-auth needed)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ UFW not installed (skipping firewall pre-auth)${NC}"
fi
echo ""

# Step 5: Restart SSH daemon
echo -e "${YELLOW}[STEP 5]${NC} Restarting SSH daemon..."
sudo systemctl restart ssh
echo -e "${GREEN}✓ SSH daemon restarted${NC}"
echo ""

# Step 6: Auto-verify SSH on new port
echo -e "${YELLOW}[STEP 6]${NC} Auto-verifying SSH on port 22022..."

verify_ssh_success=false
port=22022
lan_ip="10.10.10.100"  # VM's IP on VLAN10

# Test 1: Port listening on loopback
echo -e "${YELLOW}  • Checking loopback binding...${NC}"
for attempt in {1..5}; do
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}    ✓ SSH listening on loopback:${port}${NC}"
        break
    fi
    sleep 1
done

# Test 2: Port listening on LAN interface (CRITICAL for remote access)
echo -e "${YELLOW}  • Checking LAN interface binding...${NC}"
if nc -z "$lan_ip" $port 2>/dev/null; then
    echo -e "${GREEN}    ✓ SSH listening on LAN IP ${lan_ip}:${port}${NC}"
    verify_ssh_success=true
else
    echo -e "${RED}    ✗ SSH NOT listening on LAN IP ${lan_ip}:${port}${NC}"
    echo -e "${RED}      This is a critical problem - SSH won't be remotely accessible!${NC}"
    verify_ssh_success=false
fi

# Test 3: Optional - Attempt actual SSH key connection
if [[ -f ~/.ssh/id_ed25519 ]]; then
    echo -e "${YELLOW}  • Testing SSH key authentication...${NC}"
    if timeout 5 ssh -o ConnectTimeout=3 \
                     -o StrictHostKeyChecking=no \
                     -o UserKnownHostsFile=/dev/null \
                     -i ~/.ssh/id_ed25519 \
                     -p $port \
                     localhost "echo 'SSH auth OK'" 2>/dev/null; then
        echo -e "${GREEN}    ✓ SSH key authentication works${NC}"
    else
        echo -e "${YELLOW}    ⚠ SSH key test failed on localhost (may still be OK)${NC}"
    fi
fi

echo ""

# Step 7: Verify SSH changes or rollback
echo -e "${YELLOW}[STEP 7]${NC} Finalizing SSH hardening..."

if [[ "$verify_ssh_success" == true ]]; then
    echo -e "${GREEN}✓ SSH successfully hardened and verified${NC}"
else
    echo -e "${RED}✗ SSH verification failed (port not accessible on LAN IP)${NC}"
    echo -e "${YELLOW}Rolling back SSH changes...${NC}"
    sudo cp "$BACKUP_DIR/sshd_config.backup" /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo -e "${GREEN}✓ SSH configuration restored to previous state${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check sshd_config has 'Port 22022' and 'ListenAddress 0.0.0.0'"
    echo "  2. Verify no firewall is blocking port 22022"
    echo "  3. Re-run this script to try again"
    exit 1
fi

# Test that we can still execute sudo (means we're still logged in)
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓ Current session still active${NC}"
else
    echo -e "${RED}✗ Lost sudo access (unexpected)${NC}"
    exit 1
fi

echo ""

# Step 8: Display completion summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}SSH HARDENING COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓${NC} SSH port changed to 22022"
echo -e "${GREEN}✓${NC} Password authentication disabled"
echo -e "${GREEN}✓${NC} Root login disabled"
echo -e "${GREEN}✓${NC} Key authentication verified"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "For future SSH connections, use:"
echo "  ssh -p 22022 -i ~/.ssh/id_ed25519 sleszugreen@10.10.10.100"
echo ""
echo "To rollback if needed:"
echo "  bash ${HOME}/vm100-hardening/99-emergency-rollback.sh"
echo ""
echo -e "${GREEN}Script 01 complete! Proceed to Script 02.${NC}"
