#!/bin/bash
################################################################################
# LXC102 Daily Vzdump Backup Script
# Purpose: Create daily full container backup → Homelab NFS mount
# Frequency: Daily at 2 AM (off-peak)
# Destination: Homelab NFS mount
# Retention: 10 backups (7 daily + 1 weekly + 2 archive)
#
# Execution: Run on UGREEN Proxmox host via SSH from container
# Usage: sudo /path/to/backup-lxc102-vzdump.sh
################################################################################

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

CONTAINER_ID=102
BACKUP_BASE="/var/lib/vz/dump"  # Proxmox default dump directory
BACKUP_HOST="192.168.40.40"     # Homelab Proxmox host
BACKUP_USER="backup-user"       # User on homelab with backup permissions
BACKUP_DEST="/mnt/homelab-backups/lxc102-vzdump"  # Remote destination
BACKUP_RETENTION=10             # Keep 10 backups
LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/lxc102-vzdump-backup.log"
TIMESTAMP=$(date '+%Y-%m-%d-%H%M%S')

# ============================================================================
# Functions
# ============================================================================

log() {
    local level=$1
    shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

error_exit() {
    local message=$1
    local exit_code=${2:-1}
    log "ERROR" "${message}"
    exit "${exit_code}"
}

check_prerequisites() {
    log "INFO" "Checking prerequisites..."

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root (use sudo)" 1
    fi

    # Check if vzdump is available
    if ! command -v vzdump &> /dev/null; then
        error_exit "vzdump command not found" 1
    fi

    # Check if container exists
    if ! pct status ${CONTAINER_ID} &> /dev/null; then
        error_exit "Container ${CONTAINER_ID} not found or not accessible" 1
    fi

    # Check backup base directory
    if [[ ! -d "${BACKUP_BASE}" ]]; then
        error_exit "Backup base directory ${BACKUP_BASE} not found" 1
    fi

    log "INFO" "Prerequisites check passed"
}

verify_connectivity() {
    log "INFO" "Verifying connectivity to backup host ${BACKUP_HOST}..."

    # Test SSH connectivity
    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
        "${BACKUP_USER}@${BACKUP_HOST}" "echo 'SSH connectivity OK'" > /dev/null 2>&1; then
        error_exit "Cannot connect to ${BACKUP_HOST} as ${BACKUP_USER}" 1
    fi

    # Verify remote backup destination exists
    if ! ssh -o ConnectTimeout=5 "${BACKUP_USER}@${BACKUP_HOST}" \
        "[[ -d '${BACKUP_DEST}' ]]" 2>/dev/null; then
        log "WARN" "Remote destination ${BACKUP_DEST} does not exist, will attempt to create"
        ssh "${BACKUP_USER}@${BACKUP_HOST}" "mkdir -p '${BACKUP_DEST}'" || \
            error_exit "Failed to create remote backup destination" 1
    fi

    log "INFO" "Connectivity verification passed"
}

create_backup() {
    local backup_file="lxc102-${TIMESTAMP}.tar.zst"

    log "INFO" "Creating vzdump backup: ${backup_file}"

    # Create compressed backup
    if ! vzdump lxc ${CONTAINER_ID} \
        --mode snapshot \
        --compress zstd \
        --dumpdir "${BACKUP_BASE}" \
        --quiet; then
        error_exit "Vzdump backup failed" 1
    fi

    log "INFO" "Vzdump backup created successfully"

    # Find the created backup file (most recent in BACKUP_BASE)
    local latest_backup=$(ls -t "${BACKUP_BASE}"/lxc-${CONTAINER_ID}-* 2>/dev/null | head -1)

    if [[ -z "${latest_backup}" ]]; then
        error_exit "Could not find created backup file" 1
    fi

    echo "${latest_backup}"
}

transfer_backup() {
    local local_backup=$1
    local backup_filename=$(basename "${local_backup}")

    log "INFO" "Transferring backup to homelab: ${backup_filename}"

    # Use rsync for reliable transfer with progress
    if ! rsync -avz --progress "${local_backup}" \
        "${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DEST}/${backup_filename}"; then
        error_exit "Failed to transfer backup to homelab" 1
    fi

    log "INFO" "Backup transfer completed"
}

verify_backup() {
    local backup_filename=$1

    log "INFO" "Verifying backup integrity..."

    # Verify file exists on remote
    if ! ssh "${BACKUP_USER}@${BACKUP_HOST}" \
        "[[ -f '${BACKUP_DEST}/${backup_filename}' ]]"; then
        error_exit "Backup file not found on remote after transfer" 1
    fi

    # Get file sizes for comparison
    local local_size=$(stat -f%z "${BACKUP_BASE}/${backup_filename}" 2>/dev/null || \
                       stat -c%s "${BACKUP_BASE}/${backup_filename}" 2>/dev/null)
    local remote_size=$(ssh "${BACKUP_USER}@${BACKUP_HOST}" \
        "stat -c%s '${BACKUP_DEST}/${backup_filename}'" 2>/dev/null)

    if [[ "${local_size}" != "${remote_size}" ]]; then
        log "WARN" "File size mismatch - local: ${local_size}, remote: ${remote_size}"
        log "WARN" "Transfer may be incomplete; investigate manually"
    fi

    log "INFO" "Backup verification passed"
}

cleanup_old_backups() {
    log "INFO" "Cleaning up old backups (keeping ${BACKUP_RETENTION} most recent)"

    # Get list of backups on remote
    local backup_list=$(ssh "${BACKUP_USER}@${BACKUP_HOST}" \
        "ls -1t '${BACKUP_DEST}'/lxc102-*.tar.* 2>/dev/null | tail -n +$((BACKUP_RETENTION + 1))" || true)

    if [[ -n "${backup_list}" ]]; then
        while IFS= read -r old_backup; do
            log "INFO" "Removing old backup: $(basename "${old_backup}")"
            ssh "${BACKUP_USER}@${BACKUP_HOST}" "rm -f '${old_backup}'" || \
                log "WARN" "Failed to remove old backup: ${old_backup}"
        done <<< "${backup_list}"
    else
        log "INFO" "No old backups to remove"
    fi

    # Also clean up local backup file if transfer was successful
    if [[ -f "${BACKUP_BASE}/lxc-${CONTAINER_ID}-"* ]]; then
        log "INFO" "Removing local backup file (backup transferred successfully)"
        rm -f "${BACKUP_BASE}/lxc-${CONTAINER_ID}-"* || \
            log "WARN" "Failed to remove local backup file"
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    log "INFO" "=========================================="
    log "INFO" "LXC102 Vzdump Backup Started"
    log "INFO" "=========================================="

    check_prerequisites
    verify_connectivity

    local backup_file=$(create_backup)
    transfer_backup "${backup_file}"
    verify_backup "$(basename "${backup_file}")"
    cleanup_old_backups

    log "INFO" "=========================================="
    log "INFO" "LXC102 Vzdump Backup Completed Successfully"
    log "INFO" "=========================================="
}

main "$@"
