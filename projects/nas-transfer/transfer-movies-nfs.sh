#!/bin/bash
# Transfer Movies (2018, 2022, 2023) from 918 NFS mount to UGREEN
# Run on Proxmox host in screen session

LOG_FILE="/root/nas-transfer-logs/movies-nfs-$(date +%Y%m%d-%H%M%S).log"

echo "=== Starting Movies Transfer (NFS Method) ===" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Source: /mnt/918-filmy918/ (NFS mounted from 918)" | tee -a "$LOG_FILE"
echo "Destination: /storage/Media/Movies918/" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if NFS mount exists
if ! mount | grep -q "918-filmy918"; then
    echo "ERROR: NFS mount /mnt/918-filmy918 not found!" | tee -a "$LOG_FILE"
    echo "Run setup-nfs-mounts.sh first" | tee -a "$LOG_FILE"
    exit 1
fi

# Check which folders exist in Filmy918
echo "Scanning available folders in /mnt/918-filmy918/..." | tee -a "$LOG_FILE"
ls -lh /mnt/918-filmy918/ | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to transfer a folder
transfer_folder() {
    local FOLDER=$1
    local SOURCE="/mnt/918-filmy918/$FOLDER/"
    local DEST="/storage/Media/Movies918/$FOLDER/"

    echo "=== Transferring $FOLDER ===" | tee -a "$LOG_FILE"
    echo "From: $SOURCE" | tee -a "$LOG_FILE"
    echo "To: $DEST" | tee -a "$LOG_FILE"

    # Check if source exists
    if [ ! -d "$SOURCE" ]; then
        echo "WARNING: Source folder $SOURCE does not exist, skipping..." | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        return 0
    fi

    # Create destination if needed
    mkdir -p "$DEST"

    # Get source size
    echo "Calculating source size..." | tee -a "$LOG_FILE"
    SOURCE_SIZE=$(du -sh "$SOURCE" | cut -f1)
    echo "Source size: $SOURCE_SIZE" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    # Start transfer
    rsync -avh \
        --progress \
        --partial \
        --append-verify \
        --stats \
        --log-file="$LOG_FILE" \
        "$SOURCE" "$DEST"

    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "✓ SUCCESS: $FOLDER transfer completed" | tee -a "$LOG_FILE"
    else
        echo "✗ ERROR: $FOLDER transfer failed with exit code $EXIT_CODE" | tee -a "$LOG_FILE"
    fi

    echo "" | tee -a "$LOG_FILE"
    return $EXIT_CODE
}

# Transfer each year folder
ERRORS=0

transfer_folder "2018" || ((ERRORS++))
transfer_folder "2022" || ((ERRORS++))
transfer_folder "2023" || ((ERRORS++))

# Final summary
echo "=== Transfer Complete ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ $ERRORS -eq 0 ]; then
    echo "✓ SUCCESS: All movies transferred successfully!" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Final destination contents:" | tee -a "$LOG_FILE"
    du -sh /storage/Media/Movies918/*/ 2>/dev/null | tee -a "$LOG_FILE"
else
    echo "✗ WARNING: $ERRORS folder(s) had errors" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
