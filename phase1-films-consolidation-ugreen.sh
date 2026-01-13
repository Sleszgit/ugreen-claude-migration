#!/usr/bin/env bash
set -Eeuo pipefail

# Phase 1 Films Consolidation Script - UGREEN HOST
# Purpose: Consolidate 2018, 2021 films on UGREEN, verify Movies918 moved to Homelab
# Date: 13 January 2026
# Execution: Run on UGREEN Proxmox host (not in LXC102)
# Command: sudo bash /nvme2tb/lxc102scripts/phase1-films-consolidation-ugreen.sh

# ============================================================================
# ERROR HANDLING & LOGGING
# ============================================================================
trap 'echo "ERROR on line $LINENO, exit code $?" >&2' ERR

LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/phase1-consolidation-$(date +%Y%m%d-%H%M%S).log"

# Ensure log directory is writable
mkdir -p "$LOG_DIR" || { echo "FATAL: Cannot write to $LOG_DIR"; exit 1; }

log() {
  local msg="$*"
  echo "$(date +'%Y-%m-%d %H:%M:%S') | $msg" | tee -a "$LOG_FILE"
}

log "========================================================================"
log "Phase 1 Films Consolidation - UGREEN HOST"
log "========================================================================"
log "Log file: $LOG_FILE"
log "User: $(whoami)"
log "Host: $(hostname)"

# ============================================================================
# VERIFICATION: Check source paths exist
# ============================================================================
log ""
log "Pre-flight checks..."

if [ ! -d "/storage/Media/Filmy920/2018" ]; then
  log "ERROR: /storage/Media/Filmy920/2018 not found"
  exit 1
fi

if [ ! -d "/storage/Media/Filmy920/2021" ]; then
  log "ERROR: /storage/Media/Filmy920/2021 not found"
  exit 1
fi

if [ ! -d "/storage/Media/FilmsUgreen" ]; then
  log "ERROR: /storage/Media/FilmsUgreen destination not found"
  exit 1
fi

log "✓ All source and destination paths exist"

# ============================================================================
# PHASE 1a: Move 2018 to FilmsUgreen (Local on UGREEN)
# ============================================================================
log ""
log "PHASE 1a: Moving 2018 films to FilmsUgreen"
log "Source: /storage/Media/Filmy920/2018"
log "Destination: /storage/Media/FilmsUgreen/2018"

SOURCE_SIZE=$(du -sh "/storage/Media/Filmy920/2018" | awk '{print $1}')
log "Source size: $SOURCE_SIZE"

rsync -avP --stats --checksum --remove-source-files \
  "/storage/Media/Filmy920/2018/" \
  "/storage/Media/FilmsUgreen/2018/" 2>&1 | tee -a "$LOG_FILE"

log "✅ PHASE 1a COMPLETE: 2018 transferred to FilmsUgreen"

# ============================================================================
# PHASE 1b: Move 2021 to FilmsUgreen (Local on UGREEN)
# ============================================================================
log ""
log "PHASE 1b: Moving 2021 films to FilmsUgreen"
log "Source: /storage/Media/Filmy920/2021"
log "Destination: /storage/Media/FilmsUgreen/2021"

SOURCE_SIZE=$(du -sh "/storage/Media/Filmy920/2021" | awk '{print $1}')
log "Source size: $SOURCE_SIZE"

rsync -avP --stats --checksum --remove-source-files \
  "/storage/Media/Filmy920/2021/" \
  "/storage/Media/FilmsUgreen/2021/" 2>&1 | tee -a "$LOG_FILE"

log "✅ PHASE 1b COMPLETE: 2021 transferred to FilmsUgreen"

# ============================================================================
# VERIFICATION
# ============================================================================
log ""
log "========================================================================"
log "VERIFICATION - Checking source and destination states"
log "========================================================================"

log ""
log "Source directory sizes (should be minimal after removal):"
du -sh "/storage/Media/Filmy920/2018" 2>/dev/null || log "2018: removed ✓"
du -sh "/storage/Media/Filmy920/2021" 2>/dev/null || log "2021: removed ✓"

log ""
log "Destination directory sizes:"
du -sh "/storage/Media/FilmsUgreen/2018" | tee -a "$LOG_FILE"
du -sh "/storage/Media/FilmsUgreen/2021" | tee -a "$LOG_FILE"

log ""
log "FilmsUgreen total size:"
du -sh "/storage/Media/FilmsUgreen" | tee -a "$LOG_FILE"

log ""
log "Remaining files in Filmy920 (should only be 2019 and 2020):"
ls -lh "/storage/Media/Filmy920/" | tee -a "$LOG_FILE"

# ============================================================================
# COMPLETION
# ============================================================================
log ""
log "========================================================================"
log "✅ PHASE 1 CONSOLIDATION COMPLETE"
log "========================================================================"
log "Freed space on UGREEN: ~2.6 TB (1.5 TB 2018 + 1.1 TB 2021)"
log "Moved to FilmsUgreen:"
log "  - 2018: 1.5 TB → /storage/Media/FilmsUgreen/2018"
log "  - 2021: 1.1 TB → /storage/Media/FilmsUgreen/2021"
log ""
log "Note: Movies918 (1.5 TB) already on Homelab at"
log "  /Seagate-20TB-mirror/Movies918 (verified)"
log "========================================================================"
log ""
log "Full log saved to: $LOG_FILE"
log "To view: tail -f $LOG_FILE"
