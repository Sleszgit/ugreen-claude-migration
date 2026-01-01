#!/bin/bash
################################################################################
# LXC102 Daily Rsync Backup Script
# Purpose: Daily incremental file sync → UGREEN NAS
# Frequency: Daily at 3 AM (after work, off-peak)
# Destination: /storage/Media/backups/lxc102-rsync/ (UGREEN NAS)
# Retention: 7 daily snapshots
#
# Protected files:
#   - ~/scripts/ (utility scripts)
#   - ~/projects/ (active projects)
#   - ~/.bashrc, ~/.bash_profile, ~/.bash_aliases (shell configs)
#   - ~/.ssh/ (SSH keys and config)
#   - ~/.local/bin/ (installed tools)
#
# Execution: Run from LXC102 container directly
# Usage: /path/to/backup-lxc102-rsync.sh
################################################################################

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

CONTAINER_USER="sleszugreen"
CONTAINER_HOME="/home/${CONTAINER_USER}"
NAS_MOUNT_POINT="/storage/Media"
BACKUP_DEST="${NAS_MOUNT_POINT}/backups/lxc102-rsync"
BACKUP_RETENTION=7  # Keep 7 daily snapshots
LOG_DIR="${CONTAINER_HOME}/logs"
LOG_FILE="${LOG_DIR}/lxc102-rsync-backup.log"
TIMESTAMP=$(date '+%Y-%m-%d')
DAILY_SNAPSHOT="${BACKUP_DEST}/daily-${TIMESTAMP}"

# Files and directories to backup
declare -a BACKUP_SOURCES=(
    "${CONTAINER_HOME}/scripts/"
    "${CONTAINER_HOME}/projects/"
    "${CONTAINER_HOME}/.bashrc"
    "${CONTAINER_HOME}/.bash_profile"
    "${CONTAINER_HOME}/.bash_aliases"
    "${CONTAINER_HOME}/.ssh/"
    "${CONTAINER_HOME}/.local/bin/"
    "${CONTAINER_HOME}/.claude/"
    "${CONTAINER_HOME}/.gemini/"
    "${CONTAINER_HOME}/.config/claude-code/"
)

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

    # Check if running as the correct user
    local current_user=$(whoami)
    if [[ "${current_user}" != "${CONTAINER_USER}" && "${current_user}" != "root" ]]; then
        error_exit "This script should be run as ${CONTAINER_USER} or root" 1
    fi

    # Check if rsync is available
    if ! command -v rsync &> /dev/null; then
        error_exit "rsync command not found" 1
    fi

    # Check if log directory exists
    if [[ ! -d "${LOG_DIR}" ]]; then
        mkdir -p "${LOG_DIR}" || error_exit "Failed to create log directory ${LOG_DIR}" 1
    fi

    log "INFO" "Prerequisites check passed"
}

verify_nas_mount() {
    log "INFO" "Verifying NAS mount point..."

    # Check if NAS mount point exists
    if [[ ! -d "${NAS_MOUNT_POINT}" ]]; then
        error_exit "NAS mount point ${NAS_MOUNT_POINT} not found" 1
    fi

    # Check if we have write permissions
    if [[ ! -w "${NAS_MOUNT_POINT}" ]]; then
        error_exit "No write permission on NAS mount point ${NAS_MOUNT_POINT}" 1
    fi

    # Create backup destination if it doesn't exist
    if [[ ! -d "${BACKUP_DEST}" ]]; then
        mkdir -p "${BACKUP_DEST}" || \
            error_exit "Failed to create backup destination ${BACKUP_DEST}" 1
        log "INFO" "Created backup destination ${BACKUP_DEST}"
    fi

    log "INFO" "NAS mount verification passed"
}

verify_backup_sources() {
    log "INFO" "Verifying backup sources..."

    local missing_count=0
    for source in "${BACKUP_SOURCES[@]}"; do
        if [[ ! -e "${source}" ]]; then
            log "WARN" "Source does not exist: ${source}"
            ((missing_count++))
        fi
    done

    if [[ ${missing_count} -eq ${#BACKUP_SOURCES[@]} ]]; then
        error_exit "All backup sources are missing" 1
    fi

    if [[ ${missing_count} -gt 0 ]]; then
        log "WARN" "Some backup sources missing, continuing with available sources"
    fi

    log "INFO" "Backup sources verification passed"
}

create_daily_snapshot() {
    log "INFO" "Creating daily snapshot directory: ${DAILY_SNAPSHOT}"

    if ! mkdir -p "${DAILY_SNAPSHOT}"; then
        error_exit "Failed to create snapshot directory" 1
    fi

    # Create .backup-metadata file with timestamp
    cat > "${DAILY_SNAPSHOT}/.backup-metadata" <<EOF
Backup Date: ${TIMESTAMP}
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
Host: $(hostname)
Container: LXC102
User: ${CONTAINER_USER}
Status: In Progress
EOF

    log "INFO" "Daily snapshot directory created"
}

backup_with_rsync() {
    log "INFO" "Starting rsync backup..."

    local rsync_log="${DAILY_SNAPSHOT}/rsync.log"
    local failed_sources=()

    for source in "${BACKUP_SOURCES[@]}"; do
        # Skip if source doesn't exist
        if [[ ! -e "${source}" ]]; then
            log "INFO" "Skipping non-existent source: ${source}"
            continue
        fi

        log "INFO" "Syncing: ${source}"

        # Determine if source is a directory or file
        local rsync_opts="-av --progress --delete"
        local dest_path="${DAILY_SNAPSHOT}/$(basename "${source}")"

        if [[ -d "${source}" ]]; then
            # For directories, ensure trailing slash for rsync
            source="${source%/}/"
            rsync_opts+=" --exclude='.git/*' --exclude='node_modules/*' --exclude='*.tmp'"
        fi

        # Execute rsync
        if rsync ${rsync_opts} "${source}" "${dest_path}" >> "${rsync_log}" 2>&1; then
            log "INFO" "Successfully synced: ${source}"
        else
            log "ERROR" "Failed to sync: ${source}"
            failed_sources+=("${source}")
        fi
    done

    # Report results
    if [[ ${#failed_sources[@]} -gt 0 ]]; then
        log "WARN" "Some sources failed to sync:"
        for failed in "${failed_sources[@]}"; do
            log "WARN" "  - ${failed}"
        done
        # Don't exit on partial failure - backup what we could
    fi

    log "INFO" "Rsync backup completed"
}

update_metadata() {
    log "INFO" "Updating backup metadata..."

    # Update status in metadata
    cat > "${DAILY_SNAPSHOT}/.backup-metadata" <<EOF
Backup Date: ${TIMESTAMP}
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
Host: $(hostname)
Container: LXC102
User: ${CONTAINER_USER}
Status: Completed
Backup Size: $(du -sh "${DAILY_SNAPSHOT}" | cut -f1)
File Count: $(find "${DAILY_SNAPSHOT}" -type f | wc -l)
EOF

    log "INFO" "Metadata updated"
}

cleanup_old_snapshots() {
    log "INFO" "Cleaning up old snapshots (keeping ${BACKUP_RETENTION} most recent)..."

    # Get list of old snapshots
    local old_snapshots=$(ls -1d "${BACKUP_DEST}"/daily-* 2>/dev/null | \
                         sort -r | tail -n +$((BACKUP_RETENTION + 1)) || true)

    if [[ -n "${old_snapshots}" ]]; then
        while IFS= read -r old_snapshot; do
            log "INFO" "Removing old snapshot: $(basename "${old_snapshot}")"
            if rm -rf "${old_snapshot}"; then
                log "INFO" "Removed: ${old_snapshot}"
            else
                log "WARN" "Failed to remove old snapshot: ${old_snapshot}"
            fi
        done <<< "${old_snapshots}"
    else
        log "INFO" "No old snapshots to remove"
    fi
}

generate_summary() {
    local backup_size=$(du -sh "${DAILY_SNAPSHOT}" | cut -f1)
    local file_count=$(find "${DAILY_SNAPSHOT}" -type f | wc -l)

    log "INFO" "=========================================="
    log "INFO" "Backup Summary"
    log "INFO" "=========================================="
    log "INFO" "Backup Location: ${DAILY_SNAPSHOT}"
    log "INFO" "Backup Size: ${backup_size}"
    log "INFO" "Files Backed Up: ${file_count}"
    log "INFO" "Backup Date: ${TIMESTAMP}"
    log "INFO" "=========================================="
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    log "INFO" "=========================================="
    log "INFO" "LXC102 Rsync Backup Started"
    log "INFO" "=========================================="

    check_prerequisites
    verify_nas_mount
    verify_backup_sources
    create_daily_snapshot
    backup_with_rsync
    update_metadata
    cleanup_old_snapshots
    generate_summary

    log "INFO" "=========================================="
    log "INFO" "LXC102 Rsync Backup Completed"
    log "INFO" "=========================================="
}

main "$@"
