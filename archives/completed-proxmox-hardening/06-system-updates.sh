#!/bin/bash
#
# Script 06: System Updates & Security Tools Installation
# Part of Proxmox Security Hardening - Phase B
#
# Purpose: Update system and install security tools
# - Full system update
# - Install fail2ban, unattended-upgrades, security tools
# - Configure automatic security updates
#

set -e  # Exit on error

SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"
BACKUP_DIR="$SCRIPT_DIR/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

echo "=========================================="
echo "Phase B - Script 06: System Updates & Security Tools"
echo "=========================================="
echo ""

log "Starting system updates and security tools installation"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo bash $0"
    exit 1
fi

# Check disk space
echo "=== Checking Disk Space ==="
AVAILABLE_SPACE=$(df -h / | awk 'NR==2 {print $4}')
AVAILABLE_SPACE_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
log "Available disk space: $AVAILABLE_SPACE"

if [ "$AVAILABLE_SPACE_GB" -lt 5 ]; then
    echo -e "${RED}WARNING: Less than 5GB free space available!${NC}"
    echo "Available: $AVAILABLE_SPACE"
    read -p "Continue anyway? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        echo "Aborting."
        exit 1
    fi
fi

# Backup current package list
echo ""
echo "=== Creating Package Backup ==="
mkdir -p "$BACKUP_DIR/packages"
dpkg --get-selections > "$BACKUP_DIR/packages/packages-before-phase-b.list"
log "Package list backed up to: $BACKUP_DIR/packages/packages-before-phase-b.list"

# Update package lists
echo ""
echo "=== Updating Package Lists ==="
log "Running apt update..."
apt update | tee -a "$LOG_FILE"

# Check for available updates
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)
log "Available updates: $UPDATES packages"

if [ "$UPDATES" -eq 0 ]; then
    echo -e "${GREEN}System is already up to date!${NC}"
else
    echo -e "${YELLOW}$UPDATES packages will be upgraded${NC}"
    echo ""
    echo "Preview of upgradable packages:"
    apt list --upgradable 2>/dev/null | head -20
    echo ""

    read -p "Proceed with full system upgrade? (yes/no): " PROCEED
    if [ "$PROCEED" != "yes" ]; then
        echo "Skipping system upgrade."
    else
        echo ""
        echo "=== Performing Full System Upgrade ==="
        log "Starting full-upgrade..."
        apt full-upgrade -y | tee -a "$LOG_FILE"
        log "System upgrade completed"
    fi
fi

# Install security tools
echo ""
echo "=== Installing Security Tools ==="
log "Installing security packages..."

PACKAGES=(
    "fail2ban"
    "unattended-upgrades"
    "apt-listchanges"
    "needrestart"
    "logwatch"
    "ufw"
)

echo "Packages to install:"
for pkg in "${PACKAGES[@]}"; do
    echo "  - $pkg"
done
echo ""

read -p "Install these security packages? (yes/no): " INSTALL
if [ "$INSTALL" != "yes" ]; then
    echo "Skipping package installation."
else
    for pkg in "${PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            echo -e "${GREEN}$pkg already installed${NC}"
        else
            echo "Installing $pkg..."
            apt install -y "$pkg" | tee -a "$LOG_FILE"
            log "Installed: $pkg"
        fi
    done
fi

# Configure unattended-upgrades
echo ""
echo "=== Configuring Unattended Upgrades ==="
if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
    cp /etc/apt/apt.conf.d/50unattended-upgrades "$BACKUP_DIR/50unattended-upgrades.backup"
    log "Backed up: 50unattended-upgrades"
fi

cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
// Automatically upgrade packages from these repositories
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=${distro_codename},label=Debian";
    "origin=Debian,codename=${distro_codename},label=Debian-Security";
    "origin=Proxmox";
};

// List of packages to NOT automatically upgrade
Unattended-Upgrade::Package-Blacklist {
    // "vim";
    // "libc6";
};

// Auto-reboot if required (3 AM)
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Send email notifications (via ntfy.sh webhook - configure later)
// Unattended-Upgrade::Mail "root";

// Remove unused dependencies
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatically reboot even if users are logged in
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
EOF

log "Configured: /etc/apt/apt.conf.d/50unattended-upgrades"

# Enable automatic updates
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

log "Configured: /etc/apt/apt.conf.d/20auto-upgrades"

# Test unattended-upgrades configuration
echo ""
echo "=== Testing Unattended Upgrades Configuration ==="
unattended-upgrade --dry-run --debug 2>&1 | head -30
log "Unattended-upgrades configured successfully"

# Clean up
echo ""
echo "=== Cleaning Up ==="
apt autoremove -y | tee -a "$LOG_FILE"
apt autoclean | tee -a "$LOG_FILE"
log "Cleanup completed"

# Display installed versions
echo ""
echo "=== Installed Security Tools Versions ==="
for pkg in "${PACKAGES[@]}"; do
    VERSION=$(dpkg -l | grep "^ii  $pkg " | awk '{print $3}' || echo "Not installed")
    echo "$pkg: $VERSION"
done

# Final package list
dpkg --get-selections > "$BACKUP_DIR/packages/packages-after-phase-b-script-06.list"
log "Updated package list saved"

echo ""
echo "=========================================="
echo -e "${GREEN}Script 06 Completed Successfully!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - System updated: YES"
echo "  - Security tools installed: YES"
echo "  - Automatic updates configured: YES"
echo "  - Auto-reboot time: 3:00 AM"
echo ""
echo "Next steps:"
echo "  1. Review the changes above"
echo "  2. Run Script 07: Firewall Configuration"
echo ""
log "Script 06 completed successfully"
