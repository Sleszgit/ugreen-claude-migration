#!/bin/bash
# Copy 918 NAS volume3 content to UGREEN 20TB mirror
# Size: 3.8TB | Files: ~200K+ | This is a SAFE COPY - no files will be deleted or modified on 918 NAS

# ⚠️ SAFETY CONFIRMATION:
# - Source is read-only NFS mount (cannot modify 918 NAS)
# - NO --delete flag (won't delete files at destination)
# - NO --remove-source-files flag (won't delete from 918 NAS)
# - Archive mode preserves all file attributes
# - Can be safely re-run (will skip existing files)

LOG_DIR="/root/nas-transfer-logs"
LOG_FILE="$LOG_DIR/volume3-archive-$(date +%Y%m%d-%H%M%S).log"
SOURCE="/mnt/918-volume3/14TB/918-Volume3-Archive-20251217/"
DEST="/storage/Media/20251220-volume3-archive/"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo "========================================" | tee -a "$LOG_FILE"
echo "  Volume3 Archive Transfer" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Source: $SOURCE" | tee -a "$LOG_FILE"
echo "Destination: $DEST" | tee -a "$LOG_FILE"
echo "Expected size: 3.8 TB" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "⚠️  SAFETY INFORMATION:" | tee -a "$LOG_FILE"
echo "- This is a COPY operation (not move/delete)" | tee -a "$LOG_FILE"
echo "- Source mount is READ-ONLY (918 NAS cannot be modified)" | tee -a "$LOG_FILE"
echo "- No destructive flags used (--delete, --remove-source-files)" | tee -a "$LOG_FILE"
echo "- Can be safely re-run without data loss" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Verify source exists
if [ ! -d "$SOURCE" ]; then
    echo "❌ ERROR: Source directory not found!" | tee -a "$LOG_FILE"
    echo "Make sure volume3 is mounted: sudo bash /home/sleszugreen/projects/nas-transfer/mount-volume3.sh" | tee -a "$LOG_FILE"
    exit 1
fi

# Create destination if it doesn't exist
if [ ! -d "$DEST" ]; then
    echo "Creating destination directory: $DEST" | tee -a "$LOG_FILE"
    mkdir -p "$DEST"
fi

echo "✅ Pre-flight checks passed" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Starting rsync copy..." | tee -a "$LOG_FILE"
echo "This will take several hours (estimated 4-6 hours for 3.8TB)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Start the copy (rsync with safe options)
rsync -avh \
  --progress \
  --partial \
  --append-verify \
  --stats \
  --log-file="$LOG_FILE" \
  "$SOURCE" "$DEST"

EXIT_CODE=$?

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "  Copy Complete" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SUCCESS: Volume3 archive copied successfully!" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Final size:" | tee -a "$LOG_FILE"
    du -sh "$DEST" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Contents:" | tee -a "$LOG_FILE"
    ls -lh "$DEST" | tee -a "$LOG_FILE"
else
    echo "❌ ERROR: Transfer exited with code $EXIT_CODE" | tee -a "$LOG_FILE"
    echo "Check log file: $LOG_FILE" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
