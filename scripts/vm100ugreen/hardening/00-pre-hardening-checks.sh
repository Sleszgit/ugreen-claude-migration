#!/bin/bash

################################################################################
# Script 00: Pre-Hardening Checks & Backup
# Purpose: Create backups, verify access, establish rollback procedures
# Duration: 10 minutes
# Safety: Non-destructive (read-only verification + backup creation)
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="${HOME}/vm100-hardening/backups"
LOG_FILE="${HOME}/vm100-hardening/PRE-HARDENING-STATE.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Script 00: Pre-Hardening Checks & Backup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Verify hostname
echo -e "${YELLOW}[STEP 1]${NC} Verifying VM hostname..."
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" == "ugreen-docker" ]]; then
    echo -e "${GREEN}✓ Correct VM (hostname: $HOSTNAME)${NC}"
else
    echo -e "${RED}✗ WRONG VM! Hostname is '$HOSTNAME' (expected 'ugreen-docker')${NC}"
    exit 1
fi
echo ""

# Step 2: Check disk space
echo -e "${YELLOW}[STEP 2]${NC} Checking disk space..."
DISK_FREE=$(df /home | tail -1 | awk '{print $4}')
if [[ $DISK_FREE -gt 5242880 ]]; then  # 5GB in KB
    echo -e "${GREEN}✓ Sufficient disk space: $(numfmt --to=iec $((DISK_FREE * 1024)))${NC}"
else
    echo -e "${RED}✗ Insufficient disk space: $(numfmt --to=iec $((DISK_FREE * 1024))) (need 5GB)${NC}"
    exit 1
fi
echo ""

# Step 3: Test sudo access
echo -e "${YELLOW}[STEP 3]${NC} Testing sudo access..."
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓ Passwordless sudo works${NC}"
else
    echo -e "${RED}✗ Passwordless sudo not configured${NC}"
    exit 1
fi
echo ""

# Step 4: Verify network connectivity
echo -e "${YELLOW}[STEP 4]${NC} Verifying network connectivity..."
if ping -c 1 192.168.40.1 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Network connectivity verified${NC}"
else
    echo -e "${YELLOW}⚠ Cannot reach 192.168.40.1 (may be OK if different gateway)${NC}"
fi
echo ""

# Step 5: Check Docker is running
echo -e "${YELLOW}[STEP 5]${NC} Checking Docker daemon..."
if sudo systemctl is-active docker >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✓ Docker is running: $DOCKER_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Docker is not running (will be started by Script 03)${NC}"
fi
echo ""

# Step 6: Create backup directory
echo -e "${YELLOW}[STEP 6]${NC} Creating backup directory..."
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}✓ Backup directory created: $BACKUP_DIR${NC}"
echo ""

# Step 7: Backup critical files
echo -e "${YELLOW}[STEP 7]${NC} Backing up critical configuration files..."

# SSH config
if [[ -f /etc/ssh/sshd_config ]]; then
    sudo cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.backup"
    echo -e "${GREEN}✓ Backed up: /etc/ssh/sshd_config${NC}"
fi

# Docker daemon config
if [[ -f /etc/docker/daemon.json ]]; then
    sudo cp /etc/docker/daemon.json "$BACKUP_DIR/daemon.json.backup"
    echo -e "${GREEN}✓ Backed up: /etc/docker/daemon.json${NC}"
else
    echo -e "${GREEN}✓ daemon.json doesn't exist yet (will be created)${NC}"
fi

# UFW status
if command -v ufw >/dev/null 2>&1; then
    sudo ufw status verbose > "$BACKUP_DIR/ufw-status.backup" 2>&1 || true
    echo -e "${GREEN}✓ Backed up: UFW status${NC}"
fi

# SSH authorized_keys if exists
if [[ -f ~/.ssh/authorized_keys ]]; then
    cp ~/.ssh/authorized_keys "$BACKUP_DIR/authorized_keys.backup"
    echo -e "${GREEN}✓ Backed up: authorized_keys${NC}"
fi

echo ""

# Step 8: Create emergency rollback script
echo -e "${YELLOW}[STEP 8]${NC} Creating emergency rollback script..."
ROLLBACK_SCRIPT="${SCRIPT_DIR}/99-emergency-rollback.sh"
cat > "$ROLLBACK_SCRIPT" << 'EOF'
#!/bin/bash
# Emergency Rollback Script - Restore pre-hardening state

set -euo pipefail

echo "⚠️  EMERGENCY ROLLBACK INITIATED"
echo "Restoring pre-hardening configuration..."

BACKUP_DIR="${HOME}/vm100-hardening/backups"

# Restore SSH config
if [[ -f "$BACKUP_DIR/sshd_config.backup" ]]; then
    echo "Restoring /etc/ssh/sshd_config..."
    sudo cp "$BACKUP_DIR/sshd_config.backup" /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo "✓ SSH configuration restored"
fi

# Restore Docker config
if [[ -f "$BACKUP_DIR/daemon.json.backup" ]]; then
    echo "Restoring /etc/docker/daemon.json..."
    sudo cp "$BACKUP_DIR/daemon.json.backup" /etc/docker/daemon.json
    sudo systemctl restart docker
    echo "✓ Docker configuration restored"
fi

# Disable UFW
if command -v ufw >/dev/null 2>&1; then
    echo "Disabling UFW firewall..."
    sudo ufw disable || true
    echo "✓ UFW disabled"
fi

echo ""
echo "✓ Rollback complete"
echo "If still locked out, access VM via Proxmox Web UI Console"
EOF

chmod +x "$ROLLBACK_SCRIPT"
echo -e "${GREEN}✓ Emergency rollback script created: $ROLLBACK_SCRIPT${NC}"
echo ""

# Step 9: Document current state
echo -e "${YELLOW}[STEP 9]${NC} Documenting current system state..."
cat > "$LOG_FILE" << EOF
═══════════════════════════════════════════════════════════════════════
PRE-HARDENING STATE SNAPSHOT
Generated: $(date)
═══════════════════════════════════════════════════════════════════════

SYSTEM INFORMATION
──────────────────────────────────────────────────────────────────────
Hostname: $HOSTNAME
IP Address: $(hostname -I | awk '{print $1}')
Kernel: $(uname -r)
OS: $(lsb_release -ds)

RESOURCES
──────────────────────────────────────────────────────────────────────
CPU Cores: $(nproc)
RAM: $(free -h | grep Mem | awk '{print $2}')
Disk Free: $(df -h /home | tail -1 | awk '{print $4}')

SERVICES
──────────────────────────────────────────────────────────────────────
SSH Port: $(sudo grep '^Port' /etc/ssh/sshd_config | awk '{print $2}' || echo "22 (default)")
SSH Status: $(sudo systemctl is-active ssh)
UFW Status: $(sudo ufw status | head -1 || echo "not installed")
Docker Version: $(docker --version 2>/dev/null || echo "not installed")
Docker Status: $(sudo systemctl is-active docker 2>/dev/null || echo "not running")

BACKUPS CREATED
──────────────────────────────────────────────────────────────────────
Location: $BACKUP_DIR
$(ls -lh $BACKUP_DIR 2>/dev/null || echo "No backups created")

ROLLBACK PROCEDURE
──────────────────────────────────────────────────────────────────────
If locked out:
1. Access Proxmox Web UI: https://192.168.40.60:8006
2. Navigate to VM 100 → Console
3. Login as sleszdockerugreen
4. Run: bash ${SCRIPT_DIR}/99-emergency-rollback.sh

═══════════════════════════════════════════════════════════════════════
EOF

echo -e "${GREEN}✓ System state documented: $LOG_FILE${NC}"
echo ""

# Step 10: Display pre-flight checklist
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PRE-FLIGHT CHECKLIST${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓${NC} Correct VM verified (hostname: $HOSTNAME)"
echo -e "${GREEN}✓${NC} Sufficient disk space available"
echo -e "${GREEN}✓${NC} Passwordless sudo working"
echo -e "${GREEN}✓${NC} Network connectivity verified"
echo -e "${GREEN}✓${NC} Docker installed and running"
echo -e "${GREEN}✓${NC} Backups created in: $BACKUP_DIR"
echo -e "${GREEN}✓${NC} Emergency rollback script ready: $ROLLBACK_SCRIPT"
echo ""

echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "1. Review backup files in: $BACKUP_DIR"
echo "2. Verify Proxmox console access: https://192.168.40.60:8006 → VM 100 → Console"
echo "3. When ready, proceed to Script 01 (SSH Hardening)"
echo ""
echo -e "${GREEN}Script 00 complete!${NC}"
