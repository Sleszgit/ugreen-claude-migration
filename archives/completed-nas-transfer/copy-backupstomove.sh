#!/bin/bash
# Copy backupstomove from 918 NAS to UGREEN with compression
# Size: 3.8TB | Files: 63,242 | Folders: 5,375

LOG_DIR="/root/nas-transfer-logs"
LOG_FILE="$LOG_DIR/backupstomove-$(date +%Y%m%d-%H%M%S).log"
SOURCE="/mnt/918-volume2/Filmy 10TB/backupstomove/"
DEST="/storage/Media/20251209backupsfrom918/"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo "========================================" | tee -a "$LOG_FILE"
echo "  backupstomove Transfer" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Source: $SOURCE" | tee -a "$LOG_FILE"
echo "Destination: $DEST" | tee -a "$LOG_FILE"
echo "Expected size: 3.8 TB" | tee -a "$LOG_FILE"
echo "Files: ~63,242 | Folders: ~5,375" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Verify source exists
if [ ! -d "$SOURCE" ]; then
    echo "❌ ERROR: Source directory not found!" | tee -a "$LOG_FILE"
    echo "Make sure volume2 is mounted: bash /home/sleszugreen/nas-transfer/mount-volume2.sh" | tee -a "$LOG_FILE"
    exit 1
fi

# Verify destination exists
if [ ! -d "/storage/Media/20251209backupsfrom918" ]; then
    echo "❌ ERROR: Compressed destination not found!" | tee -a "$LOG_FILE"
    echo "Run setup first: bash /home/sleszugreen/nas-transfer/setup-compressed-backup.sh" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ Pre-flight checks passed" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Starting rsync transfer..." | tee -a "$LOG_FILE"
echo "This will take several hours (estimated 8-12 hours for 3.8TB)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Start the transfer
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
echo "  Transfer Complete" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SUCCESS: backupstomove transferred successfully!" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Checking compression ratio..." | tee -a "$LOG_FILE"
    sudo zfs get compressratio,used,available storage/Media/20251209backupsfrom918 | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Final size:" | tee -a "$LOG_FILE"
    du -sh "$DEST" | tee -a "$LOG_FILE"
else
    echo "❌ ERROR: Transfer exited with code $EXIT_CODE" | tee -a "$LOG_FILE"
    echo "Check log file: $LOG_FILE" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
