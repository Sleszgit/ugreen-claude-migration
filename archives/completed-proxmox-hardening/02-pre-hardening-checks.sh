#!/bin/bash
#########################################################################
# Proxmox Hardening - Phase A Script 2
# Pre-Hardening Checks & Backups
#
# Purpose: Create backups and verify emergency access methods before
#          making any security changes
#
# Run as: sudo bash 02-pre-hardening-checks.sh
#########################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"
BACKUP_DIR="$SCRIPT_DIR/backups"

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

info() {
    echo -e "${CYAN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
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

section "Pre-Hardening Safety Checks"

log "Starting pre-hardening verification and backup process..."
log "This ensures we can recover if anything goes wrong"

# Get system information
section "System Information"

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
PROXMOX_VERSION=$(pveversion | cut -d'/' -f2)
KERNEL_VERSION=$(uname -r)
CURRENT_USER=${SUDO_USER:-$USER}

log "Hostname: $HOSTNAME"
log "IP Address: $IP_ADDRESS"
log "Proxmox Version: $PROXMOX_VERSION"
log "Kernel: $KERNEL_VERSION"
log "Running as user: $CURRENT_USER"
echo ""

# Verify console access warning
section "CRITICAL: Emergency Access Verification"

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                   ⚠️  CRITICAL SAFETY CHECK  ⚠️                     ║
╚════════════════════════════════════════════════════════════════════╝

Before proceeding with hardening, you MUST verify emergency access:

1. PHYSICAL CONSOLE ACCESS
   - Do you have physical access to this server?
   - Can you connect a monitor and keyboard if needed?

2. PROXMOX WEB UI ACCESS
   - Can you access https://192.168.40.60:8006 from your desktop?
   - Can you login with your credentials?

3. WEB UI SHELL ACCESS (EMERGENCY BACKUP)
   - In the Web UI, click on the node in the left sidebar
   - Click the "Shell" button at the top
   - Verify a shell terminal opens in your browser
   - This is your EMERGENCY ACCESS if SSH fails!

EOF

warn "If you lose SSH access, the Web UI Shell is your backup!"
echo ""

read -p "Do you have physical OR Web UI Shell access? (yes/no): " access_confirm

if [[ "$access_confirm" != "yes" ]]; then
    error "You MUST have emergency access before hardening!"
    error "Operation cancelled for safety"
    exit 1
fi

log "✓ Emergency access confirmed"

# Check network connectivity
section "Network Connectivity Check"

log "Checking network connectivity..."

if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    log "✓ Internet connectivity verified"
else
    warn "Internet connectivity test failed"
    warn "Some features may not work without internet"
fi

# Check disk space
section "Disk Space Check"

log "Checking available disk space..."
df -h / | tee -a "$LOG_FILE"
echo ""

DISK_AVAIL=$(df / | tail -1 | awk '{print $4}')
if [[ $DISK_AVAIL -lt 1048576 ]]; then  # Less than 1GB
    warn "Low disk space detected!"
    warn "Available: $(df -h / | tail -1 | awk '{print $4}')"
    warn "Consider freeing up space before continuing"
    read -p "Continue anyway? (yes/no): " disk_confirm
    if [[ "$disk_confirm" != "yes" ]]; then
        exit 0
    fi
else
    log "✓ Sufficient disk space available"
fi

# Create backup directory structure
section "Creating Backup Directory Structure"

mkdir -p "$BACKUP_DIR/config"
mkdir -p "$BACKUP_DIR/scripts"
mkdir -p "$BACKUP_DIR/logs"

log "✓ Backup directories created"
log "Location: $BACKUP_DIR"

# Backup critical configuration files
section "Backing Up Critical Configuration Files"

backup_file() {
    local source=$1
    local dest_dir=${2:-$BACKUP_DIR/config}
    local timestamp=$(date +%Y%m%d_%H%M%S)

    if [[ -f "$source" ]]; then
        local filename=$(basename "$source")
        local backup_path="$dest_dir/${filename}.backup.$timestamp"
        cp -p "$source" "$backup_path"
        log "✓ Backed up: $source"
        return 0
    elif [[ -d "$source" ]]; then
        local dirname=$(basename "$source")
        local backup_path="$dest_dir/${dirname}.backup.$timestamp"
        cp -rp "$source" "$backup_path"
        log "✓ Backed up directory: $source"
        return 0
    else
        warn "File not found (skipped): $source"
        return 1
    fi
}

log "Backing up SSH configuration..."
backup_file "/etc/ssh/sshd_config"

log "Backing up Proxmox firewall configuration..."
if [[ -d /etc/pve/firewall ]]; then
    backup_file "/etc/pve/firewall"
fi

log "Backing up network configuration..."
backup_file "/etc/network/interfaces"
backup_file "/etc/hosts"
backup_file "/etc/resolv.conf"

log "Backing up system configuration..."
backup_file "/etc/fstab"
backup_file "/etc/sysctl.conf"
[[ -f /etc/systemd/timesyncd.conf ]] && backup_file "/etc/systemd/timesyncd.conf"

log "Backing up repository configuration..."
backup_file "/etc/apt/sources.list"
[[ -f /etc/apt/sources.list.d/pve-enterprise.list ]] && backup_file "/etc/apt/sources.list.d/pve-enterprise.list"
[[ -f /etc/apt/sources.list.d/pve-no-subscription.list ]] && backup_file "/etc/apt/sources.list.d/pve-no-subscription.list"

# Create package list
section "Creating Package List Backup"

log "Saving installed package list..."
dpkg --get-selections > "$BACKUP_DIR/packages.list.$(date +%Y%m%d_%H%M%S)"
log "✓ Package list saved"

# Backup current firewall rules
section "Backing Up Current Firewall Rules"

log "Saving current iptables rules..."
iptables-save > "$BACKUP_DIR/iptables.rules.$(date +%Y%m%d_%H%M%S)"
log "✓ iptables rules saved"

# Record current service status
section "Recording Service Status"

log "Recording currently running services..."
systemctl list-units --type=service --state=running --no-pager > "$BACKUP_DIR/services.running.$(date +%Y%m%d_%H%M%S)"
log "✓ Service status recorded"

# Create emergency rollback script
section "Creating Emergency Rollback Script"

ROLLBACK_SCRIPT="$SCRIPT_DIR/99-emergency-rollback.sh"

cat > "$ROLLBACK_SCRIPT" << 'ROLLBACK_EOF'
#!/bin/bash
#########################################################################
# EMERGENCY ROLLBACK SCRIPT
#
# Purpose: Restore Proxmox to pre-hardening state
# Use this ONLY if something goes wrong!
#
# Run as: sudo bash 99-emergency-rollback.sh
#########################################################################

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                    ⚠️  EMERGENCY ROLLBACK  ⚠️                       ║
║                                                                    ║
║  This will restore Proxmox to pre-hardening configuration!        ║
║  Only use this if you are locked out or have serious issues!      ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

read -p "Are you SURE you want to rollback? (type 'ROLLBACK' to confirm): " confirm

if [[ "$confirm" != "ROLLBACK" ]]; then
    echo "Cancelled."
    exit 0
fi

BACKUP_DIR="/root/proxmox-hardening/backups/config"

echo "Restoring SSH configuration..."
if ls $BACKUP_DIR/sshd_config.backup.* 1> /dev/null 2>&1; then
    LATEST_SSHD=$(ls -t $BACKUP_DIR/sshd_config.backup.* | head -1)
    cp "$LATEST_SSHD" /etc/ssh/sshd_config
    systemctl restart sshd
    echo "✓ SSH config restored"
fi

echo "Disabling firewall..."
systemctl stop pve-firewall
systemctl disable pve-firewall
echo "✓ Firewall disabled"

echo "Restoring network configuration..."
if ls $BACKUP_DIR/interfaces.backup.* 1> /dev/null 2>&1; then
    LATEST_NET=$(ls -t $BACKUP_DIR/interfaces.backup.* | head -1)
    cp "$LATEST_NET" /etc/network/interfaces
    echo "✓ Network config restored"
fi

echo ""
echo -e "${GREEN}Rollback complete!${NC}"
echo ""
echo "SSH should now be accessible on default port 22 with password"
echo "Firewall is disabled"
echo ""
echo "You may need to:"
echo "1. Restart networking: systemctl restart networking"
echo "2. Reboot the system: reboot"
echo ""

ROLLBACK_EOF

chmod +x "$ROLLBACK_SCRIPT"
log "✓ Emergency rollback script created: $ROLLBACK_SCRIPT"

# Test sudo access
section "Verifying Sudo Access"

if sudo -n true 2>/dev/null; then
    log "✓ Sudo access verified (passwordless sudo configured)"
else
    log "✓ Sudo access available (password required)"
fi

# Display current security status
section "Current Security Status"

log "SSH Configuration:"
echo "  Port: $(grep "^Port" /etc/ssh/sshd_config 2>/dev/null || echo "22 (default)")"
echo "  PermitRootLogin: $(grep "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null || echo "yes (default)")"
echo "  PasswordAuthentication: $(grep "^PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null || echo "yes (default)")"
echo ""

log "Firewall Status:"
systemctl is-active pve-firewall || echo "  pve-firewall: inactive"
echo ""

log "Current open ports:"
ss -tlnp | grep -E ':(22|8006|3128|111|5405)' || echo "  Unable to determine"
echo ""

# Create a pre-flight checklist
section "Pre-Flight Safety Checklist"

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                    PRE-HARDENING CHECKLIST                         ║
╚════════════════════════════════════════════════════════════════════╝

Please verify the following BEFORE proceeding with hardening:

 [ ] You have PHYSICAL access to this server (monitor + keyboard)
     OR
 [ ] You have tested Proxmox Web UI Shell access and it works

 [ ] You can access Proxmox Web UI: https://192.168.40.60:8006

 [ ] You have at least 2 SSH terminal sessions open to this server

 [ ] You are connected from your trusted IP: 192.168.99.6

 [ ] You have read the hardening plan and understand the changes

 [ ] You know how to use the emergency rollback script:
     sudo bash /root/proxmox-hardening/99-emergency-rollback.sh

⚠️  CRITICAL WARNINGS:

  • ALWAYS keep at least 2 SSH sessions open during hardening
  • DO NOT close your last session until you verify the next step works
  • The Web UI Shell is your emergency backup access method
  • Physical access is the final fallback if everything else fails

EOF

echo ""
read -p "Have you completed the checklist above? (yes/no): " checklist_confirm

if [[ "$checklist_confirm" != "yes" ]]; then
    warn "Please review the checklist before proceeding"
    exit 0
fi

# Summary
section "Pre-Hardening Checks Complete"

echo ""
log "✓ System information recorded"
log "✓ Emergency access verified"
log "✓ Configuration files backed up"
log "✓ Package list saved"
log "✓ Firewall rules backed up"
log "✓ Emergency rollback script created"
log "✓ Pre-flight checklist reviewed"
echo ""

log "Backup location: $BACKUP_DIR"
log "Emergency rollback: $ROLLBACK_SCRIPT"
echo ""

log "You are now ready to proceed with hardening!"
log "Next step: Run 03-smart-monitoring.sh"
echo ""

warn "REMINDER: Keep at least 2 SSH sessions open at all times!"
echo ""

log "Script completed successfully!"

exit 0
