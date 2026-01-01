#!/bin/bash
################################################################################
# LXC102 Disaster Recovery / Restore Script
# Purpose: Restore LXC102 from backup (full or partial recovery)
#
# Two restore modes:
#   1. Full container restore: from vzdump backup (bare metal recovery)
#   2. Partial restore: individual files from rsync snapshot (corruption recovery)
#
# Usage:
#   # List available backups
#   ./restore-lxc102.sh list-vzdump
#   ./restore-lxc102.sh list-rsync
#
#   # Restore full container from vzdump
#   ./restore-lxc102.sh restore-vzdump <backup-filename>
#
#   # Restore individual files from rsync snapshot
#   ./restore-lxc102.sh restore-rsync <snapshot-date> <source-file> [<dest-file>]
#
################################################################################

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

CONTAINER_ID=102
BACKUP_HOST="192.168.40.40"
BACKUP_USER="backup-user"
BACKUP_DEST="/mnt/homelab-backups/lxc102-vzdump"
NAS_MOUNT_POINT="/storage/Media"
RSYNC_BACKUP_DEST="${NAS_MOUNT_POINT}/backups/lxc102-rsync"
CONTAINER_USER="sleszugreen"
CONTAINER_HOME="/home/${CONTAINER_USER}"

# ============================================================================
# Functions
# ============================================================================

log() {
    local level=$1
    shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}"
}

error_exit() {
    local message=$1
    local exit_code=${2:-1}
    log "ERROR" "${message}"
    exit "${exit_code}"
}

show_usage() {
    cat <<EOF
LXC102 Restore Script - Disaster Recovery & File Recovery

USAGE:
  $0 <command> [options]

COMMANDS:

  list-vzdump
    List all available vzdump backups on Homelab

  list-rsync
    List all available rsync daily snapshots on UGREEN NAS

  restore-vzdump <backup-filename>
    Restore entire LXC102 from a vzdump backup
    Example: $0 restore-vzdump lxc102-2026-01-01-020000.tar.zst
    WARNING: This overwrites the current container!

  restore-rsync <snapshot-date> <source-path> [destination-path]
    Restore individual files from a daily rsync snapshot
    Example: $0 restore-rsync 2026-01-01 ~/.bashrc ~/.bashrc.restored

  help
    Show this help message

EOF
}

list_vzdump_backups() {
    log "INFO" "Listing vzdump backups from ${BACKUP_HOST}:${BACKUP_DEST}..."

    ssh "${BACKUP_USER}@${BACKUP_HOST}" \
        "ls -lh '${BACKUP_DEST}'/lxc102-*.tar.* 2>/dev/null | awk '{print \$9, \"(\" \$5 \")\"}'" || \
        error_exit "Failed to list backups from homelab" 1
}

list_rsync_snapshots() {
    log "INFO" "Listing rsync snapshots from ${RSYNC_BACKUP_DEST}..."

    if [[ ! -d "${RSYNC_BACKUP_DEST}" ]]; then
        error_exit "UGREEN NAS backup destination not found: ${RSYNC_BACKUP_DEST}" 1
    fi

    ls -1d "${RSYNC_BACKUP_DEST}"/daily-* 2>/dev/null | xargs -I{} basename {} | sort -r || \
        error_exit "No rsync snapshots found" 1
}

check_restore_prerequisites() {
    log "INFO" "Checking restore prerequisites..."

    # For vzdump restore, need to be root on Proxmox host
    # For rsync restore, need access to NAS mount
    if [[ ! -d "${RSYNC_BACKUP_DEST}" ]]; then
        error_exit "Cannot access rsync backups at ${RSYNC_BACKUP_DEST}" 1
    fi

    log "INFO" "Prerequisites check passed"
}

restore_from_vzdump() {
    local backup_filename=$1

    log "INFO" "=========================================="
    log "INFO" "FULL CONTAINER RESTORE FROM VZDUMP"
    log "INFO" "=========================================="
    log "WARN" "WARNING: This will overwrite LXC102!"
    log "WARN" "Ensure you have verified the backup integrity"
    log "WARN" "Current container will be stopped and replaced"
    log "INFO" "=========================================="

    read -p "Continue with restore? (type 'YES' to confirm): " confirm
    if [[ "${confirm}" != "YES" ]]; then
        log "INFO" "Restore cancelled"
        return 0
    fi

    log "INFO" "Downloading backup from homelab..."

    # Create temporary directory for backup
    local temp_dir="/tmp/lxc102-restore-$$"
    mkdir -p "${temp_dir}"

    # Download backup from homelab
    log "INFO" "Downloading: ${backup_filename}"
    if ! rsync -avz --progress "${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_DEST}/${backup_filename}" \
        "${temp_dir}/"; then
        error_exit "Failed to download backup" 1
    fi

    log "INFO" "Backup downloaded to ${temp_dir}"
    log "INFO" "To restore this backup on Proxmox host, run:"
    log "INFO" "  sudo pct restore ${CONTAINER_ID} ${temp_dir}/${backup_filename}"
    log "INFO" ""
    log "INFO" "Cleanup when done: rm -rf ${temp_dir}"
}

restore_from_rsync() {
    local snapshot_date=$1
    local source_path=$2
    local dest_path=${3:-$source_path}

    log "INFO" "=========================================="
    log "INFO" "PARTIAL FILE RESTORE FROM RSYNC SNAPSHOT"
    log "INFO" "=========================================="
    log "INFO" "Snapshot Date: ${snapshot_date}"
    log "INFO" "Source File: ${source_path}"
    log "INFO" "Destination: ${dest_path}"
    log "INFO" "=========================================="

    # Check if snapshot exists
    local snapshot_dir="${RSYNC_BACKUP_DEST}/daily-${snapshot_date}"
    if [[ ! -d "${snapshot_dir}" ]]; then
        error_exit "Snapshot not found: ${snapshot_dir}" 1
    fi

    # Check if source file exists in snapshot
    local backup_file="${snapshot_dir}/$(basename "${source_path}")"
    if [[ ! -e "${backup_file}" ]]; then
        # Try alternate path (with directory structure preserved)
        backup_file="${snapshot_dir}${source_path}"
        if [[ ! -e "${backup_file}" ]]; then
            error_exit "Source file not found in snapshot: ${source_path}" 1
        fi
    fi

    log "INFO" "Found file in backup: ${backup_file}"
    log "INFO" "Restoring to: ${dest_path}"

    # Create backup of current file if it exists
    if [[ -e "${dest_path}" ]]; then
        local backup_ext=".backup.$(date '+%Y%m%d-%H%M%S')"
        log "INFO" "Creating backup of current file: ${dest_path}${backup_ext}"
        cp -p "${dest_path}" "${dest_path}${backup_ext}"
    fi

    # Restore file
    if [[ -d "${backup_file}" ]]; then
        # Source is a directory
        cp -r "${backup_file}" "${dest_path}" || \
            error_exit "Failed to restore directory" 1
    else
        # Source is a file
        cp -p "${backup_file}" "${dest_path}" || \
            error_exit "Failed to restore file" 1
    fi

    log "INFO" "File restored successfully"
    log "INFO" "Verify restored file: ls -la '${dest_path}'"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    local command=${1:-help}

    case "${command}" in
        list-vzdump)
            list_vzdump_backups
            ;;
        list-rsync)
            list_rsync_snapshots
            ;;
        restore-vzdump)
            if [[ $# -lt 2 ]]; then
                error_exit "restore-vzdump requires backup filename argument" 1
            fi
            check_restore_prerequisites
            restore_from_vzdump "$2"
            ;;
        restore-rsync)
            if [[ $# -lt 3 ]]; then
                error_exit "restore-rsync requires snapshot-date and source-path arguments" 1
            fi
            check_restore_prerequisites
            restore_from_rsync "$2" "$3" "${4:-}"
            ;;
        help)
            show_usage
            ;;
        *)
            error_exit "Unknown command: ${command}" 1
            ;;
    esac
}

main "$@"
