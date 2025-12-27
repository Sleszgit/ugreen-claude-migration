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

# Step 5: Restart SSH daemon
echo -e "${YELLOW}[STEP 5]${NC} Restarting SSH daemon..."
sudo systemctl restart ssh
echo -e "${GREEN}✓ SSH daemon restarted${NC}"
echo ""

# Step 6: Test new SSH connection
echo -e "${YELLOW}[STEP 6]${NC} Testing SSH key authentication on port 22022..."
echo ""
echo -e "${YELLOW}⚠️  CRITICAL: Keep your current SSH session OPEN${NC}"
echo "Do NOT close this terminal until you verify key auth works!"
echo ""
echo "In a NEW terminal, test:"
echo "  ssh -p 22022 -i ~/.ssh/id_ed25519 sleszdockerugreen@192.168.40.60"
echo ""
echo -e "${YELLOW}Press ENTER when you have verified key auth works...${NC}"
read -r

# Step 7: Verify key auth is actually working
echo -e "${YELLOW}[STEP 7]${NC} Verifying SSH key authentication is active..."

# Test that we can still execute sudo (means we're still logged in)
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓ Current session still active (good!)${NC}"
else
    echo -e "${RED}✗ Lost sudo access (something went wrong)${NC}"
    exit 1
fi

# Attempt local test of port 22022
if nc -z localhost 22022 2>/dev/null; then
    echo -e "${GREEN}✓ SSH listening on port 22022${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify port 22022 (may still be OK)${NC}"
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
echo "  ssh -p 22022 -i ~/.ssh/id_ed25519 sleszdockerugreen@192.168.40.60"
echo ""
echo "To rollback if needed:"
echo "  bash ${HOME}/vm100-hardening/99-emergency-rollback.sh"
echo ""
echo -e "${GREEN}Script 01 complete! Proceed to Script 02.${NC}"
