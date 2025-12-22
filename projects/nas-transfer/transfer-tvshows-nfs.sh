#!/bin/bash
# Transfer TV Shows from 918 NFS mount to UGREEN
# Run on Proxmox host in screen session

LOG_FILE="/root/nas-transfer-logs/tvshows-nfs-$(date +%Y%m%d-%H%M%S).log"

echo "=== Starting TV Shows Transfer (NFS Method) ===" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Source: /mnt/918-series918/ (NFS mounted from 918)" | tee -a "$LOG_FILE"
echo "Destination: /storage/Media/Series918/" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if NFS mount exists
if ! mount | grep -q "918-series918"; then
    echo "ERROR: NFS mount /mnt/918-series918 not found!" | tee -a "$LOG_FILE"
    echo "Run setup-nfs-mounts.sh first" | tee -a "$LOG_FILE"
    exit 1
fi

# Check what's in Series918
echo "Scanning available folders in /mnt/918-series918/..." | tee -a "$LOG_FILE"
ls -lh /mnt/918-series918/ | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if TVshows918 subfolder exists
if [ -d "/mnt/918-series918/TVshows918" ]; then
    SOURCE="/mnt/918-series918/TVshows918/"
    DEST="/storage/Media/Series918/TVshows918/"
    echo "Found TVshows918 subfolder, transferring that specifically" | tee -a "$LOG_FILE"
else
    SOURCE="/mnt/918-series918/"
    DEST="/storage/Media/Series918/"
    echo "No TVshows918 subfolder found, transferring entire Series918" | tee -a "$LOG_FILE"
fi

echo "From: $SOURCE" | tee -a "$LOG_FILE"
echo "To: $DEST" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Create destination
mkdir -p "$DEST"

# Get source size
echo "Calculating source size..." | tee -a "$LOG_FILE"
SOURCE_SIZE=$(du -sh "$SOURCE" | cut -f1)
echo "Source size: $SOURCE_SIZE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Start transfer
echo "Starting rsync transfer..." | tee -a "$LOG_FILE"
rsync -avh \
    --progress \
    --partial \
    --append-verify \
    --stats \
    --log-file="$LOG_FILE" \
    "$SOURCE" "$DEST"

EXIT_CODE=$?

# Summary
echo "" | tee -a "$LOG_FILE"
echo "=== Transfer Complete ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ SUCCESS: TV shows transfer completed successfully!" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Final destination size:" | tee -a "$LOG_FILE"
    du -sh "$DEST" | tee -a "$LOG_FILE"
else
    echo "✗ ERROR: Transfer exited with code $EXIT_CODE" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
