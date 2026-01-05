#!/usr/bin/env bash
set -Eeuo pipefail

# Script: apply-lxc102-zfs-fix.sh
# Purpose: Fix LXC 102 startup race condition by creating custom systemd service
# that waits for ZFS mounts before starting the container

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SERVICE_FILE="/etc/systemd/system/lxc-102-custom.service"
readonly LOG_FILE="/var/log/lxc102-fix-setup.log"
readonly LOG_DIR="/var/log"
readonly CONTAINER_ID="102"

# =============================================================================
# ERROR HANDLING & LOGGING
# =============================================================================

trap 'echo "ERROR on line $LINENO, exit code $?" >> "$LOG_FILE"' ERR

log() {
    local message="$1"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    log "FATAL ERROR: $message"
    exit "$exit_code"
}

# =============================================================================
# STEP 0: VALIDATION
# =============================================================================

log "Starting LXC 102 ZFS Fix Setup..."

# Validate we're running as root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root (use sudo)" 1
fi

# Validate log directory exists and is writable
if ! mkdir -p "$LOG_DIR"; then
    error_exit "Cannot create log directory: $LOG_DIR" 1
fi

if ! touch "$LOG_FILE"; then
    error_exit "Cannot write to log file: $LOG_FILE" 1
fi

log "Pre-flight checks passed (root verified, logging ready)"

# Validate container exists
if ! pct status "$CONTAINER_ID" > /dev/null 2>&1; then
    error_exit "Container $CONTAINER_ID does not exist or is inaccessible" 1
fi
log "Container $CONTAINER_ID verified"

# =============================================================================
# STEP 1: DISABLE PROXMOX AUTO-START
# =============================================================================

log "Step 1/3: Disabling Proxmox auto-start for container $CONTAINER_ID..."
if pct set "$CONTAINER_ID" -onboot 0; then
    log "✓ Auto-start disabled successfully"
else
    error_exit "Failed to disable auto-start for container $CONTAINER_ID" 1
fi

# =============================================================================
# STEP 2: CREATE CUSTOM SYSTEMD SERVICE
# =============================================================================

log "Step 2/3: Creating custom systemd service file at $SERVICE_FILE..."

# Backup existing service file if it exists
if [[ -f "$SERVICE_FILE" ]]; then
    local backup_file
    backup_file="${SERVICE_FILE}.backup.$(date +%s)"
    log "Backing up existing service file to: $backup_file"
    if ! cp "$SERVICE_FILE" "$backup_file"; then
        error_exit "Failed to backup existing service file" 1
    fi
fi

# Create the service file with exact content
if ! cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Start LXC 102 only after ZFS Storage is Ready
# Wait for ZFS mount service and local fs
After=zfs-mount.service local-fs.target
# CRITICAL: The service will wait indefinitely until these paths exist
RequiresMountsFor=/nvme2tb /storage/Media

[Service]
Type=oneshot
# Command to start the container
ExecStart=/usr/sbin/pct start 102
# Command to stop the container cleanly
ExecStop=/usr/sbin/pct stop 102
# Keep the service status as "active" after the start command finishes
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
then
    error_exit "Failed to create systemd service file" 1
fi

log "✓ Service file created successfully"

# Verify service file permissions
if ! chmod 644 "$SERVICE_FILE"; then
    error_exit "Failed to set permissions on service file" 1
fi
log "Service file permissions set to 644"

# =============================================================================
# STEP 3: ENABLE THE NEW SERVICE
# =============================================================================

log "Step 3/3: Registering and enabling the systemd service..."

if ! systemctl daemon-reload; then
    error_exit "Failed to run systemctl daemon-reload" 1
fi
log "✓ Systemd daemon reloaded"

if ! systemctl enable lxc-102-custom.service; then
    error_exit "Failed to enable lxc-102-custom.service" 1
fi
log "✓ Service enabled successfully"

# =============================================================================
# VERIFICATION & SUCCESS
# =============================================================================

log "=========================================="
log "✓ ALL STEPS COMPLETED SUCCESSFULLY"
log "=========================================="
log ""
log "Summary of changes applied:"
log "  1. Disabled Proxmox auto-start for container $CONTAINER_ID"
log "  2. Created custom systemd service: $SERVICE_FILE"
log "  3. Enabled systemd service with daemon-reload"
log ""
log "Next steps:"
log "  • Test the service: systemctl start lxc-102-custom.service"
log "  • Check status: systemctl status lxc-102-custom.service"
log "  • View logs: journalctl -u lxc-102-custom.service -f"
log ""
log "After a system reboot, container 102 will auto-start with ZFS protection."
log "Full log available at: $LOG_FILE"
log ""

exit 0
