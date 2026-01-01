#!/bin/bash
#########################################################################
# Proxmox Hardening - Phase A Script 0
# Repository Configuration
#
# Purpose: Fix Proxmox repositories to enable updates and remove
#          "no valid subscription" popup
#
# Run as: sudo bash 00-repository-setup.sh
#########################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"
BACKUP_DIR="$SCRIPT_DIR/backups"

# Create directories if they don't exist
mkdir -p "$SCRIPT_DIR" "$BACKUP_DIR"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n" | tee -a "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   echo "Please run: sudo bash $0"
   exit 1
fi

# Check if this is a Proxmox system
if [[ ! -d /etc/pve ]]; then
    error "This does not appear to be a Proxmox VE system!"
    exit 1
fi

section "Proxmox Repository Configuration"

log "Starting Proxmox repository setup..."
log "This will fix the 'no valid subscription' popup and enable free updates"

# Backup existing repository files
section "Backing Up Repository Configuration"

backup_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        local backup_name="$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$BACKUP_DIR/$backup_name"
        log "Backed up: $file -> $BACKUP_DIR/$backup_name"
    fi
}

backup_file "/etc/apt/sources.list"
backup_file "/etc/apt/sources.list.d/pve-enterprise.list"
[[ -f "/etc/apt/sources.list.d/pve-no-subscription.list" ]] && backup_file "/etc/apt/sources.list.d/pve-no-subscription.list"
[[ -f "/etc/apt/sources.list.d/ceph.list" ]] && backup_file "/etc/apt/sources.list.d/ceph.list"

# Show current repository configuration
section "Current Repository Configuration"

log "Current /etc/apt/sources.list:"
cat /etc/apt/sources.list | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [[ -f /etc/apt/sources.list.d/pve-enterprise.list ]]; then
    log "Current /etc/apt/sources.list.d/pve-enterprise.list:"
    cat /etc/apt/sources.list.d/pve-enterprise.list | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
fi

# Prompt for confirmation
echo ""
warn "This will disable the Enterprise repository (requires paid subscription)"
warn "and enable the no-subscription repository (free updates)."
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    error "Operation cancelled by user"
    exit 0
fi

# Disable Enterprise repository
section "Disabling Enterprise Repository"

if [[ -f /etc/apt/sources.list.d/pve-enterprise.list ]]; then
    # Comment out the enterprise repo
    echo "# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
    log "✓ Disabled Enterprise repository"
else
    log "Enterprise repository file not found (already disabled or fresh install)"
fi

# Add no-subscription repository
section "Enabling No-Subscription Repository"

NO_SUB_REPO="/etc/apt/sources.list.d/pve-no-subscription.list"

# Detect Debian version
DEBIAN_VERSION=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
log "Detected Debian version: $DEBIAN_VERSION"

if [[ -f "$NO_SUB_REPO" ]]; then
    warn "No-subscription repository file already exists"
    log "Current content:"
    cat "$NO_SUB_REPO" | tee -a "$LOG_FILE"
else
    # Create no-subscription repository
    echo "deb http://download.proxmox.com/debian/pve $DEBIAN_VERSION pve-no-subscription" > "$NO_SUB_REPO"
    log "✓ Created no-subscription repository configuration"
fi

# Disable Ceph enterprise repo if it exists (optional)
if [[ -f /etc/apt/sources.list.d/ceph.list ]]; then
    section "Disabling Ceph Enterprise Repository"
    sed -i 's/^deb/#deb/g' /etc/apt/sources.list.d/ceph.list
    log "✓ Disabled Ceph enterprise repository"
fi

# Update package lists
section "Updating Package Lists"

log "Running apt update to refresh package lists..."
apt update 2>&1 | tee -a "$LOG_FILE"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    log "✓ Package lists updated successfully"
else
    error "apt update failed - please check the output above"
    exit 1
fi

# Verify Proxmox packages are available
section "Verifying Proxmox Package Availability"

log "Checking pve-manager package availability..."
apt-cache policy pve-manager | tee -a "$LOG_FILE"

# Show summary
section "Repository Configuration Complete"

echo ""
log "✓ Enterprise repository disabled"
log "✓ No-subscription repository enabled"
log "✓ Package lists updated"
echo ""

log "New repository configuration:"
echo ""
echo "=== /etc/apt/sources.list.d/pve-enterprise.list ==="
cat /etc/apt/sources.list.d/pve-enterprise.list
echo ""
echo "=== /etc/apt/sources.list.d/pve-no-subscription.list ==="
cat /etc/apt/sources.list.d/pve-no-subscription.list
echo ""

warn "IMPORTANT: The 'no valid subscription' popup will be removed after"
warn "you clear your browser cache and reload the Proxmox Web UI."
echo ""

log "Backups saved to: $BACKUP_DIR"
log "Script completed successfully!"

# Rollback instructions
section "Rollback Instructions"

cat << 'EOF'
If you need to rollback this configuration:

1. Restore enterprise repository:
   sudo cp $BACKUP_DIR/pve-enterprise.list.backup.* /etc/apt/sources.list.d/pve-enterprise.list

2. Remove no-subscription repository:
   sudo rm /etc/apt/sources.list.d/pve-no-subscription.list

3. Update package lists:
   sudo apt update

EOF

exit 0
