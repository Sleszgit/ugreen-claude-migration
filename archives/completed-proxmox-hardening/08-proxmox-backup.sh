#!/bin/bash
#
# Script 08: Proxmox Configuration Backup
# Part of Proxmox Security Hardening - Phase B
#
# Purpose: Create complete backup of Proxmox configuration
# - Backup /etc/pve directory
# - Backup system configs
# - Create restoration instructions
# - OPTIONAL: Can be skipped if not needed
#

set -e  # Exit on error

SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"
BACKUP_DIR="$SCRIPT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_ARCHIVE="$BACKUP_DIR/proxmox-backup-$TIMESTAMP.tar.gz"

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
echo "Phase B - Script 08: Proxmox Configuration Backup"
echo "=========================================="
echo ""
echo -e "${YELLOW}NOTE: This script is OPTIONAL${NC}"
echo "You can skip this if you don't need a backup."
echo ""

log "Starting Proxmox backup"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo bash $0"
    exit 1
fi

# Ask if user wants to proceed
read -p "Do you want to create a Proxmox configuration backup? (yes/no): " PROCEED
if [ "$PROCEED" != "yes" ]; then
    echo "Skipping backup. This is optional and can be done later."
    log "Backup skipped by user"
    exit 0
fi

# Check disk space
echo ""
echo "=== Checking Disk Space ==="
AVAILABLE_SPACE=$(df -h $BACKUP_DIR | awk 'NR==2 {print $4}')
AVAILABLE_SPACE_GB=$(df -BG $BACKUP_DIR | awk 'NR==2 {print $4}' | sed 's/G//')
log "Available disk space: $AVAILABLE_SPACE"

if [ "$AVAILABLE_SPACE_GB" -lt 2 ]; then
    echo -e "${RED}WARNING: Less than 2GB free space available!${NC}"
    echo "Available: $AVAILABLE_SPACE"
    read -p "Continue anyway? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        echo "Aborting backup."
        exit 1
    fi
fi

# Create backup directory
mkdir -p "$BACKUP_DIR/phase-b-backup-$TIMESTAMP"
TEMP_BACKUP_DIR="$BACKUP_DIR/phase-b-backup-$TIMESTAMP"

echo ""
echo "=== Backing Up Proxmox Configuration ==="

# Backup /etc/pve (Proxmox cluster configuration)
echo "Backing up /etc/pve..."
if [ -d /etc/pve ]; then
    cp -r /etc/pve "$TEMP_BACKUP_DIR/etc-pve"
    log "Backed up: /etc/pve"
fi

# Backup critical system configs
echo "Backing up system configuration files..."
mkdir -p "$TEMP_BACKUP_DIR/etc"

CONFIGS=(
    "/etc/ssh/sshd_config"
    "/etc/hosts"
    "/etc/hostname"
    "/etc/network/interfaces"
    "/etc/resolv.conf"
    "/etc/apt/sources.list"
    "/etc/apt/sources.list.d"
    "/etc/systemd/system"
    "/etc/cron.d"
    "/etc/crontab"
)

for config in "${CONFIGS[@]}"; do
    if [ -e "$config" ]; then
        cp -r "$config" "$TEMP_BACKUP_DIR/etc/" 2>/dev/null || true
        echo "  - $config"
    fi
done

# Backup installed packages list
echo "Backing up package list..."
dpkg --get-selections > "$TEMP_BACKUP_DIR/packages.list"
apt-mark showauto > "$TEMP_BACKUP_DIR/packages-auto.list"
log "Package lists backed up"

# Backup user accounts
echo "Backing up user accounts..."
cp /etc/passwd "$TEMP_BACKUP_DIR/passwd.backup"
cp /etc/group "$TEMP_BACKUP_DIR/group.backup"
cp /etc/shadow "$TEMP_BACKUP_DIR/shadow.backup"
log "User accounts backed up"

# Backup current firewall rules
echo "Backing up firewall rules..."
if command -v iptables-save &> /dev/null; then
    iptables-save > "$TEMP_BACKUP_DIR/iptables.rules"
    log "iptables rules backed up"
fi

# Backup running services list
echo "Backing up services list..."
systemctl list-units --type=service --state=running > "$TEMP_BACKUP_DIR/running-services.list"
log "Services list backed up"

# Create restoration instructions
cat > "$TEMP_BACKUP_DIR/RESTORE_INSTRUCTIONS.txt" <<'EOF'
# Proxmox Configuration Backup - Restoration Instructions

## Created by: Proxmox Hardening Script 08
## Timestamp: $(date)

### What's Included:
- /etc/pve (Proxmox cluster configuration)
- System configuration files (/etc/)
- Package lists
- User accounts
- Firewall rules
- Running services list

### To Restore:

1. Extract backup archive:
   tar -xzf proxmox-backup-TIMESTAMP.tar.gz

2. Restore specific configurations:

   # SSH configuration
   cp etc/ssh/sshd_config /etc/ssh/sshd_config
   systemctl restart ssh

   # Network configuration
   cp etc/network/interfaces /etc/network/interfaces
   systemctl restart networking

   # Firewall rules
   iptables-restore < iptables.rules

   # Proxmox configuration (CAUTION!)
   # Only restore if you know what you're doing
   # cp -r etc-pve/* /etc/pve/

3. Restore packages (if needed):
   dpkg --set-selections < packages.list
   apt-get dselect-upgrade

### Emergency Rollback:
If hardening causes issues, you can restore original configs:
- SSH: Restore sshd_config and restart SSH
- Firewall: Clear rules with: iptables -F
- Network: Restore interfaces file and restart networking

### IMPORTANT NOTES:
- Test each restoration step carefully
- Keep multiple SSH sessions open during restoration
- Have physical/console access available if possible
EOF

log "Restoration instructions created"

# Create compressed archive
echo ""
echo "=== Creating Compressed Archive ==="
cd "$BACKUP_DIR"
tar -czf "$BACKUP_ARCHIVE" "phase-b-backup-$TIMESTAMP"
log "Created archive: $BACKUP_ARCHIVE"

# Display archive info
ARCHIVE_SIZE=$(du -h "$BACKUP_ARCHIVE" | cut -f1)
echo ""
echo "Archive created: $BACKUP_ARCHIVE"
echo "Archive size: $ARCHIVE_SIZE"

# Clean up temporary directory
rm -rf "$TEMP_BACKUP_DIR"

# Display contents
echo ""
echo "=== Backup Contents ==="
tar -tzf "$BACKUP_ARCHIVE" | head -30
echo "... (use 'tar -tzf $BACKUP_ARCHIVE' to see all files)"

echo ""
echo "=========================================="
echo -e "${GREEN}Script 08 Completed Successfully!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Backup created: $BACKUP_ARCHIVE"
echo "  - Backup size: $ARCHIVE_SIZE"
echo "  - Restoration instructions: Included in archive"
echo ""
echo "To view backup contents:"
echo "  tar -tzf $BACKUP_ARCHIVE"
echo ""
echo "To extract backup:"
echo "  tar -xzf $BACKUP_ARCHIVE"
echo ""
echo "Next steps:"
echo "  1. Optionally copy backup to safe location"
echo "  2. Run Script 09: SSH Hardening"
echo ""
log "Script 08 completed successfully - Backup: $BACKUP_ARCHIVE"
