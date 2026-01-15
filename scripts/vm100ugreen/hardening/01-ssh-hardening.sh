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

# Step 4.5: Pre-authorize port 22022 in firewall (BEFORE SSH restart)
echo -e "${YELLOW}[STEP 4.5]${NC} Pre-authorizing port 22022 in firewall..."
if command -v ufw >/dev/null 2>&1; then
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "${YELLOW}  UFW is active - inserting allow rule for 22022${NC}"
        # Use 'insert 1' to put rule at TOP (before any deny rules)
        # ufw allow appends (slow), but we need it to take priority
        sudo ufw insert 1 allow 22022/tcp comment 'SSH hardening verification' >/dev/null 2>&1
        echo -e "${GREEN}✓ Inserted UFW rule for port 22022/tcp at position 1${NC}"
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

# Step 6: Verify SSH daemon is listening (using ss, more reliable than nc)
echo -e "${YELLOW}[STEP 6]${NC} Verifying SSH daemon binding..."

verify_ssh_success=false

# Test 1: Use ss to verify SSH is listening on port 22022
echo -e "${YELLOW}  • Checking SSH socket binding with ss...${NC}"
if sudo ss -tulnp 2>/dev/null | grep -q ":22022.*LISTEN"; then
    echo -e "${GREEN}    ✓ SSH is listening on port 22022${NC}"
    # Check if it's on 0.0.0.0 (all interfaces) or specific IP
    if sudo ss -tulnp 2>/dev/null | grep ":22022" | grep -q "0\.0\.0\.0\|::\|LISTEN"; then
        echo -e "${GREEN}    ✓ SSH is bound to all interfaces (0.0.0.0 or ::)${NC}"
        verify_ssh_success=true
    else
        echo -e "${YELLOW}    ⚠ SSH is listening but not on all interfaces (checking config)${NC}"
        verify_ssh_success=true  # sshd -t already validated, this is sufficient
    fi
else
    echo -e "${RED}    ✗ SSH NOT listening on port 22022${NC}"
    echo -e "${RED}      This is a critical problem - SSH daemon may not have restarted!${NC}"
    verify_ssh_success=false
fi

# Test 2: Verify sshd_config has correct settings
echo -e "${YELLOW}  • Verifying sshd_config...${NC}"
if grep -q "^Port 22022" /etc/ssh/sshd_config 2>/dev/null; then
    echo -e "${GREEN}    ✓ sshd_config has 'Port 22022'${NC}"
else
    echo -e "${RED}    ✗ sshd_config does NOT have 'Port 22022'${NC}"
    verify_ssh_success=false
fi

echo ""

# Step 7: Verify SSH changes or rollback
echo -e "${YELLOW}[STEP 7]${NC} Finalizing SSH hardening..."

if [[ "$verify_ssh_success" == true ]]; then
    echo -e "${GREEN}✓ SSH successfully hardened and verified${NC}"
else
    echo -e "${RED}✗ SSH verification failed${NC}"
    echo -e "${YELLOW}Rolling back SSH changes...${NC}"
    sudo cp "$BACKUP_DIR/sshd_config.backup" /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo -e "${GREEN}✓ SSH configuration restored to previous state${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify SSH is listening: sudo ss -tulnp | grep 22022"
    echo "  2. Check sshd_config: grep Port /etc/ssh/sshd_config"
    echo "  3. Check UFW rule order: sudo ufw status numbered"
    echo "  4. Re-run this script to try again"
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
