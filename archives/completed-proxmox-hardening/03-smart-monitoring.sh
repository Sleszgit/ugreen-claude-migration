#!/bin/bash
#########################################################################
# Proxmox Hardening - Phase A Script 3
# SMART Disk Monitoring Setup
#
# Purpose: Configure disk health monitoring to prevent data loss from
#          disk failures with early warning alerts
#
# Run as: sudo bash 03-smart-monitoring.sh
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
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   echo "Please run: sudo bash $0"
   exit 1
fi

section "SMART Disk Health Monitoring Setup"

log "Starting SMART monitoring configuration..."
log "This will monitor disk health and alert before failures occur"

# Check if smartmontools is installed
section "Installing SMART Monitoring Tools"

if command -v smartctl &> /dev/null; then
    log "smartmontools already installed"
    SMARTCTL_VERSION=$(smartctl --version | head -1)
    log "Version: $SMARTCTL_VERSION"
else
    log "Installing smartmontools..."
    apt update -qq
    apt install -y smartmontools
    log "✓ smartmontools installed"
fi

# Backup existing smartd configuration
section "Backing Up Configuration"

SMARTD_CONF="/etc/smartd.conf"

if [[ -f "$SMARTD_CONF" ]]; then
    backup_name="smartd.conf.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$SMARTD_CONF" "$BACKUP_DIR/$backup_name"
    log "Backed up: $SMARTD_CONF -> $BACKUP_DIR/$backup_name"
fi

# Detect all disks
section "Detecting Storage Devices"

log "Scanning for storage devices..."
echo ""

# Find all block devices
DISKS=$(lsblk -d -n -o NAME,SIZE,TYPE,TRAN 2>/dev/null | grep -E "disk|nvme" | awk '{print "/dev/"$1}')

if [[ -z "$DISKS" ]]; then
    error "No disks detected!"
    exit 1
fi

log "Detected storage devices:"
lsblk -d -o NAME,SIZE,TYPE,TRAN,MODEL | grep -E "NAME|disk|nvme" | tee -a "$LOG_FILE"
echo ""

# Test SMART capability on each disk
section "Testing SMART Capability"

SMART_CAPABLE_DISKS=()

for disk in $DISKS; do
    info "Testing $disk..."

    if smartctl -i "$disk" &> /dev/null; then
        # Check if SMART is available
        SMART_AVAILABLE=$(smartctl -i "$disk" 2>/dev/null | grep -i "SMART support is: Available" || echo "")

        if [[ -n "$SMART_AVAILABLE" ]]; then
            log "✓ $disk: SMART capable"
            SMART_CAPABLE_DISKS+=("$disk")

            # Show basic disk info
            MODEL=$(smartctl -i "$disk" 2>/dev/null | grep "Device Model:" | cut -d: -f2 | xargs || echo "Unknown")
            SERIAL=$(smartctl -i "$disk" 2>/dev/null | grep "Serial Number:" | cut -d: -f2 | xargs || echo "Unknown")
            CAPACITY=$(smartctl -i "$disk" 2>/dev/null | grep "User Capacity:" | cut -d: -f2 | cut -d'[' -f2 | cut -d']' -f1 || echo "Unknown")

            echo "  Model: $MODEL"
            echo "  Serial: $SERIAL"
            echo "  Capacity: $CAPACITY"
            echo ""
        else
            warn "$disk: SMART not available"
        fi
    else
        warn "$disk: Cannot access SMART data (may be in RAID or virtual)"
    fi
done

if [[ ${#SMART_CAPABLE_DISKS[@]} -eq 0 ]]; then
    warn "No SMART-capable disks found!"
    warn "This may be normal for virtual machines or certain RAID configurations"
    read -p "Continue anyway? (yes/no): " continue_confirm
    if [[ "$continue_confirm" != "yes" ]]; then
        exit 0
    fi
fi

# Enable SMART on all capable disks
section "Enabling SMART on Capable Disks"

for disk in "${SMART_CAPABLE_DISKS[@]}"; do
    log "Enabling SMART on $disk..."
    if smartctl -s on "$disk" &> /dev/null; then
        log "✓ SMART enabled on $disk"
    else
        warn "Could not enable SMART on $disk (may already be enabled)"
    fi
done

# Run initial health check
section "Initial Health Check"

for disk in "${SMART_CAPABLE_DISKS[@]}"; do
    echo ""
    log "Health check for $disk:"

    HEALTH_STATUS=$(smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" || echo "Unknown")
    echo "  $HEALTH_STATUS"

    # Check for any pre-existing issues
    if echo "$HEALTH_STATUS" | grep -q "PASSED"; then
        log "✓ $disk: Health check PASSED"
    else
        warn "$disk: Health check did not pass - investigate immediately!"
        smartctl -a "$disk" | tee -a "$LOG_FILE"
    fi
done

echo ""

# Create SMART alert script
section "Creating SMART Alert Script"

ALERT_SCRIPT="/usr/local/bin/smart-alert.sh"

cat > "$ALERT_SCRIPT" << 'EOF'
#!/bin/bash
#########################################################################
# SMART Alert Script
# Called by smartd when disk issues are detected
#########################################################################

SMARTD_MESSAGE="$SMARTD_MESSAGE"
SMARTD_DEVICE="$SMARTD_DEVICE"
SMARTD_FAILTYPE="$SMARTD_FAILTYPE"

# Check if ntfy notification script exists
if [[ -f /usr/local/bin/send-security-alert.sh ]]; then
    /usr/local/bin/send-security-alert.sh \
        "⚠️ SMART ALERT: Disk ${SMARTD_DEVICE} - ${SMARTD_FAILTYPE}: ${SMARTD_MESSAGE}" \
        "urgent"
else
    # Fallback to system log
    logger -t smartd "SMART ALERT: Device ${SMARTD_DEVICE} - ${SMARTD_FAILTYPE}: ${SMARTD_MESSAGE}"
fi

# Also send email if mail is configured
if command -v mail &> /dev/null; then
    echo "SMART Alert on $(hostname): ${SMARTD_MESSAGE}" | mail -s "DISK ALERT: ${SMARTD_DEVICE}" root
fi
EOF

chmod +x "$ALERT_SCRIPT"
log "✓ SMART alert script created: $ALERT_SCRIPT"

# Create SMART status check script
section "Creating SMART Status Script"

STATUS_SCRIPT="/usr/local/bin/smart-status.sh"

cat > "$STATUS_SCRIPT" << 'EOF'
#!/bin/bash
#########################################################################
# SMART Status Script
# Display health status of all disks
#########################################################################

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                  SMART Disk Health Status                          ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Find all disks
DISKS=$(lsblk -d -n -o NAME,TYPE 2>/dev/null | grep -E "disk|nvme" | awk '{print "/dev/"$1}')

for disk in $DISKS; do
    if smartctl -i "$disk" &> /dev/null 2>&1; then
        MODEL=$(smartctl -i "$disk" 2>/dev/null | grep "Device Model:" | cut -d: -f2 | xargs || \
                smartctl -i "$disk" 2>/dev/null | grep "Model Number:" | cut -d: -f2 | xargs || \
                echo "Unknown")
        HEALTH=$(smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" | cut -d: -f2 | xargs || echo "Unknown")
        TEMP=$(smartctl -A "$disk" 2>/dev/null | grep -i "Temperature" | head -1 | awk '{print $10}' || echo "N/A")

        echo "Device: $disk"
        echo "  Model: $MODEL"
        echo "  Health: $HEALTH"
        echo "  Temperature: ${TEMP}°C"
        echo ""
    fi
done

echo "Run 'smartctl -a /dev/sdX' for detailed information"
EOF

chmod +x "$STATUS_SCRIPT"
log "✓ SMART status script created: $STATUS_SCRIPT"

# Configure smartd
section "Configuring smartd Daemon"

log "Creating smartd configuration..."

cat > "$SMARTD_CONF" << 'EOF'
# smartd.conf - Configuration file for smartd
# Generated by Proxmox Hardening Script
#
# Monitors all disks and runs tests automatically

# DEVICESCAN: Monitor all disks automatically
# -a: Monitor all attributes
# -o on: Enable automatic offline testing
# -S on: Enable automatic attribute autosave
# -n standby,q: Don't wake up disks in standby mode
# -s: Schedule self-tests
#     (S/../.././02): Short test daily at 2 AM
#     (L/../../6/03): Long test weekly on Saturday at 3 AM
# -W: Temperature monitoring (4°C difference, 35°C info, 40°C critical)
# -m: Email alerts (will use alert script instead)
# -M exec: Execute custom alert script

DEVICESCAN -a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,35,40 -m root -M exec /usr/local/bin/smart-alert.sh

# Examples for specific disk monitoring:
# /dev/sda -a -o on -S on -s (S/../.././02|L/../../6/03) -m root
# /dev/sdb -a -o on -S on -s (S/../.././02|L/../../6/03) -m root

EOF

log "✓ smartd configuration created"

info "Test schedule configured:"
echo "  • Short self-test: Daily at 2:00 AM"
echo "  • Long self-test: Weekly on Saturday at 3:00 AM"
echo "  • Temperature monitoring: Warning at 35°C, Critical at 40°C"
echo ""

# Enable and start smartd service
section "Enabling smartd Service"

log "Enabling smartd service..."
systemctl enable smartd 2>&1 | tee -a "$LOG_FILE"

log "Starting smartd service..."
systemctl restart smartd 2>&1 | tee -a "$LOG_FILE"

# Wait a moment
sleep 2

# Check service status
log "Verifying smartd service status..."
if systemctl is-active --quiet smartd; then
    log "✓ smartd service is active and running"
else
    error "smartd service failed to start!"
    systemctl status smartd --no-pager | tee -a "$LOG_FILE"
    exit 1
fi

# Display current status
section "Current SMART Status"

log "Running SMART status check..."
echo ""
bash "$STATUS_SCRIPT" | tee -a "$LOG_FILE"

# Test notification (if ntfy is set up)
section "Testing Alert System"

if [[ -f /usr/local/bin/send-security-alert.sh ]]; then
    log "Testing SMART alert notification..."
    /usr/local/bin/send-security-alert.sh "SMART monitoring enabled on $(hostname) - All systems nominal" "low" 2>/dev/null || true
    log "✓ Test notification sent (check your ntfy app)"
else
    warn "ntfy notification script not found"
    warn "Alerts will go to system log only"
    warn "Install ntfy in Phase C for mobile alerts"
fi

# Summary
section "SMART Monitoring Setup Complete"

echo ""
log "✓ smartmontools installed and configured"
log "✓ SMART enabled on ${#SMART_CAPABLE_DISKS[@]} disk(s)"
log "✓ Automatic self-tests scheduled"
log "✓ Temperature monitoring active"
log "✓ Alert script configured"
log "✓ smartd service running"
echo ""

log "Scripts created:"
echo "  • SMART status: $STATUS_SCRIPT"
echo "  • SMART alerts: $ALERT_SCRIPT"
echo ""

log "Configuration file: $SMARTD_CONF"
log "Backup saved to: $BACKUP_DIR"
echo ""

info "Useful commands:"
echo "  • Check SMART status: sudo smart-status.sh"
echo "  • View disk details: sudo smartctl -a /dev/sdX"
echo "  • Check service: sudo systemctl status smartd"
echo "  • View smartd log: sudo journalctl -u smartd -f"
echo ""

log "Script completed successfully!"
log "Next step: Run 04-ssh-key-setup.sh"

exit 0
