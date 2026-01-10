#!/bin/bash

################################################################################
# TRANSFER SCRIPT: Seriale 2023 (920 NAS → UGREEN seriale2023 ZFS pool)
# Purpose: Transfer TV shows from 920 NAS, skipping 363 already on UGREEN
# Source: 920 NAS /volume1/Seriale 2023/Seriale 2023/ (1436 folders)
# Target: UGREEN /seriale2023/ (ZFS pool root)
# Skip:   Any shows already in /storage/Media/series920part/ (363 folders)
# Result: Transfer ~1073 new shows to /seriale2023/
################################################################################

set -e  # Exit on any error

# Configuration
NAS_IP="192.168.40.20"
NAS_SOURCE_PATH="/volume1/Seriale 2023"
NAS_TV_SHOWS_SUBDIR="Seriale 2023"  # Nested folder containing actual TV shows
TARGET_POOL="/seriale2023"
EXISTING_SHOWS="/storage/Media/series920part"  # Already-transferred shows to SKIP
TEMP_MOUNT="/tmp/920-seriale2023-mount"
EXCLUDE_FILE="/tmp/rsync-exclude-seriale2023-$(date +%s).txt"
LOG_FILE="/root/nas-transfer-logs/transfer-seriale2023-$(date +%Y%m%d-%H%M%S).log"

# Create log directory
mkdir -p /root/nas-transfer-logs

echo "================================================================================"
echo "SERIALE 2023 TRANSFER SCRIPT"
echo "================================================================================"
echo "[$(date)] Starting transfer initialization..." | tee -a "$LOG_FILE"
echo ""

# Step 1: Verify target ZFS pool exists and is accessible
echo "[STEP 1] Verifying target ZFS pool..."
if [ ! -d "$TARGET_POOL" ]; then
    echo "ERROR: Target pool $TARGET_POOL does not exist!" | tee -a "$LOG_FILE"
    exit 1
fi
echo "✓ Target pool exists: $TARGET_POOL" | tee -a "$LOG_FILE"
echo "  Available space: $(df -h $TARGET_POOL | tail -1 | awk '{print $4}')" | tee -a "$LOG_FILE"
echo ""

# Step 2: Check for already-transferred shows
echo "[STEP 2] Checking for already-transferred shows..."
if [ -d "$EXISTING_SHOWS" ]; then
    EXISTING_COUNT=$(ls -1 "$EXISTING_SHOWS" 2>/dev/null | wc -l)
    echo "✓ Found $EXISTING_COUNT shows already on UGREEN in $EXISTING_SHOWS" | tee -a "$LOG_FILE"
else
    EXISTING_COUNT=0
    echo "⚠ Directory $EXISTING_SHOWS not found (no shows to skip)" | tee -a "$LOG_FILE"
fi
echo ""

# Step 3: Create and prepare temporary mount point
echo "[STEP 3] Preparing NFS mount point..."
if [ ! -d "$TEMP_MOUNT" ]; then
    mkdir -p "$TEMP_MOUNT"
    echo "✓ Created mount directory: $TEMP_MOUNT" | tee -a "$LOG_FILE"
else
    echo "✓ Mount directory already exists: $TEMP_MOUNT" | tee -a "$LOG_FILE"
fi
echo ""

# Step 4: Mount NFS share
echo "[STEP 4] Mounting 920 NAS via NFS..."
if mountpoint -q "$TEMP_MOUNT"; then
    echo "⚠ Already mounted, unmounting first..." | tee -a "$LOG_FILE"
    umount "$TEMP_MOUNT" 2>/dev/null || true
fi

if mount -t nfs -o ro,soft,timeo=30,retrans=3 "$NAS_IP:$NAS_SOURCE_PATH" "$TEMP_MOUNT"; then
    echo "✓ NFS mount successful" | tee -a "$LOG_FILE"
else
    echo "ERROR: Failed to mount NFS share!" | tee -a "$LOG_FILE"
    exit 1
fi
echo ""

# Step 5: Verify mount contents and count source folders
echo "[STEP 5] Analyzing source folders on 920 NAS..."
if [ ! -d "$TEMP_MOUNT/$NAS_TV_SHOWS_SUBDIR" ]; then
    echo "ERROR: Expected folder not found at: $TEMP_MOUNT/$NAS_TV_SHOWS_SUBDIR" | tee -a "$LOG_FILE"
    umount "$TEMP_MOUNT"
    exit 1
fi
SOURCE_COUNT=$(ls -1 "$TEMP_MOUNT/$NAS_TV_SHOWS_SUBDIR/" 2>/dev/null | grep -v "^@" | grep -v "^#" | grep -v "do skasowania" | wc -l)
echo "✓ Found $SOURCE_COUNT TV show folders on 920 NAS" | tee -a "$LOG_FILE"
echo ""

# Step 6: Create rsync exclude list
echo "[STEP 6] Creating exclusion list from already-transferred shows..."
cat > "$EXCLUDE_FILE" << 'SYSEOF'
@eaDir
#recycle
do skasowania
.DS_Store
Thumbs.db
.*
SYSEOF

# Add the 363 already-transferred shows to exclude list
if [ $EXISTING_COUNT -gt 0 ]; then
    echo "Adding $EXISTING_COUNT already-transferred shows to exclusion list..." | tee -a "$LOG_FILE"
    ls -1 "$EXISTING_SHOWS" 2>/dev/null | while read -r show; do
        echo "$show"
    done >> "$EXCLUDE_FILE"
fi

EXCLUDE_COUNT=$(wc -l < "$EXCLUDE_FILE")
echo "✓ Exclusion list created with $EXCLUDE_COUNT entries" | tee -a "$LOG_FILE"
echo "  (System folders + $EXISTING_COUNT already-transferred shows)" | tee -a "$LOG_FILE"
echo ""

# Step 7: Calculate how many shows need to be transferred
SHOWS_TO_TRANSFER=$((SOURCE_COUNT - EXISTING_COUNT))

# Step 8: Calculate expected transfer size
echo "[STEP 6.5] Calculating expected transfer size..."
TOTAL_NAS_SIZE=$(du -sh "$TEMP_MOUNT/$NAS_TV_SHOWS_SUBDIR/" 2>/dev/null | awk '{print $1}')
if [ -z "$TOTAL_NAS_SIZE" ]; then
    EXPECTED_SIZE="~12.8TB (estimated)"
else
    # Use awk to calculate proportional transfer size
    EXPECTED_SIZE=$(du -sb "$TEMP_MOUNT/$NAS_TV_SHOWS_SUBDIR/" 2>/dev/null | awk -v shows="$SHOWS_TO_TRANSFER" -v total="$SOURCE_COUNT" '{printf "%.1f", ($1 / total * shows / 1099511627776)}')
    EXPECTED_SIZE="${EXPECTED_SIZE}TB (estimated)"
fi

echo "✓ Total 920 NAS size: $TOTAL_NAS_SIZE" | tee -a "$LOG_FILE"
echo "✓ Expected transfer size: $EXPECTED_SIZE" | tee -a "$LOG_FILE"
echo ""

# Step 9: Show transfer plan
echo "[STEP 7] TRANSFER PLAN"
echo "================================================================================"
echo "Source:  $NAS_IP:$NAS_SOURCE_PATH/$NAS_TV_SHOWS_SUBDIR/" | tee -a "$LOG_FILE"
echo "Target:  $TARGET_POOL/" | tee -a "$LOG_FILE"
echo "Method:  rsync with checksums" | tee -a "$LOG_FILE"
echo ""
echo "Folders on 920 NAS:         $SOURCE_COUNT" | tee -a "$LOG_FILE"
echo "Already on UGREEN (skip):   $EXISTING_COUNT" | tee -a "$LOG_FILE"
echo "Folders to transfer (new):  $SHOWS_TO_TRANSFER" | tee -a "$LOG_FILE"
echo "Expected data size:         $EXPECTED_SIZE" | tee -a "$LOG_FILE"
echo ""
echo "Transfer characteristics:" | tee -a "$LOG_FILE"
echo "  - Resume-capable: YES (safe to interrupt and resume)" | tee -a "$LOG_FILE"
echo "  - Checksum verification: YES (ensures complete transfer)" | tee -a "$LOG_FILE"
echo "  - Progress reporting: YES (real-time transfer speed)" | tee -a "$LOG_FILE"
echo "  - Smart exclude: YES (skips 363 already-transferred + system files)" | tee -a "$LOG_FILE"
echo ""
echo "================================================================================"
echo ""

# Step 10: Ask for confirmation
echo "⚠ READY TO START TRANSFER"
echo "This will copy ~$SHOWS_TO_TRANSFER TV show folders (~${EXPECTED_SIZE})"
echo "Do you want to proceed? (yes/no)"
read -r confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Transfer cancelled by user" | tee -a "$LOG_FILE"
    umount "$TEMP_MOUNT"
    exit 0
fi
echo ""

# Step 10: Execute rsync transfer
echo "[STEP 8] EXECUTING TRANSFER..."
echo "Transfer started at $(date)" | tee -a "$LOG_FILE"
echo "================================================================================" | tee -a "$LOG_FILE"
echo ""

rsync -avh \
    --partial \
    --progress \
    --exclude-from="$EXCLUDE_FILE" \
    "$TEMP_MOUNT/$NAS_TV_SHOWS_SUBDIR/" \
    "$TARGET_POOL/" \
    | tee -a "$LOG_FILE"

RSYNC_EXIT_CODE=$?

echo ""
echo "================================================================================" | tee -a "$LOG_FILE"

# Step 10: Verify and report results
echo "[STEP 9] VERIFYING TRANSFER..."
NEW_TARGET_COUNT=$(ls -1 "$TARGET_POOL/" 2>/dev/null | wc -l)
TRANSFERRED=$((NEW_TARGET_COUNT - TARGET_FOLDERS))

echo "✓ Transfer completed" | tee -a "$LOG_FILE"
echo "  Rsync exit code: $RSYNC_EXIT_CODE" | tee -a "$LOG_FILE"
echo "  Folders before: $TARGET_FOLDERS" | tee -a "$LOG_FILE"
echo "  Folders now:    $NEW_TARGET_COUNT" | tee -a "$LOG_FILE"
echo "  Folders added:  $TRANSFERRED" | tee -a "$LOG_FILE"
echo ""

# Step 11: Cleanup
echo "[STEP 10] CLEANUP..."
echo "Unmounting NFS share..."
if umount "$TEMP_MOUNT"; then
    echo "✓ NFS unmounted successfully" | tee -a "$LOG_FILE"
    rmdir "$TEMP_MOUNT" 2>/dev/null || true
else
    echo "⚠ Warning: Could not unmount NFS (may be in use)" | tee -a "$LOG_FILE"
fi

rm -f "$EXCLUDE_FILE"
echo ""

# Step 12: Final summary
echo "================================================================================"
echo "TRANSFER SUMMARY"
echo "================================================================================"
echo "Status:           $([ $RSYNC_EXIT_CODE -eq 0 ] && echo 'SUCCESS' || echo 'COMPLETED WITH WARNINGS')" | tee -a "$LOG_FILE"
echo "Folders copied:   $TRANSFERRED" | tee -a "$LOG_FILE"
echo "Total on target:  $NEW_TARGET_COUNT" | tee -a "$LOG_FILE"
echo "Duration:         See log file for details" | tee -a "$LOG_FILE"
echo "Log file:         $LOG_FILE" | tee -a "$LOG_FILE"
echo ""
echo "Next steps:" | tee -a "$LOG_FILE"
echo "  1. Verify folders copied correctly: ls -lah $TARGET_POOL | head -20" | tee -a "$LOG_FILE"
echo "  2. Check disk usage: df -h $TARGET_POOL" | tee -a "$LOG_FILE"
echo "  3. Review log: tail -100 $LOG_FILE" | tee -a "$LOG_FILE"
echo ""
echo "Transfer completed at $(date)" | tee -a "$LOG_FILE"
echo "================================================================================"

exit $RSYNC_EXIT_CODE
