#!/bin/bash
# Transfer TVshows918 from 918 NAS to UGREEN
# Source: /volume1/Series918/TVshows918
# Destination: /storage/Media/Series918/

LOG_FILE="/root/nas-transfer-logs/tvshows918-$(date +%Y%m%d-%H%M%S).log"
SOURCE="nas918:/volume1/Series918/TVshows918/"
DEST="/storage/Media/Series918/"

echo "=== Starting TVshows918 Transfer ===" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Source: $SOURCE" | tee -a "$LOG_FILE"
echo "Destination: $DEST" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

rsync -avh \
  --progress \
  --partial \
  --append-verify \
  --stats \
  --log-file="$LOG_FILE" \
  "$SOURCE" "$DEST/TVshows918/"

EXIT_CODE=$?

echo "" | tee -a "$LOG_FILE"
echo "=== Transfer Complete ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$LOG_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: TVshows918 transfer completed successfully!" | tee -a "$LOG_FILE"
else
    echo "ERROR: Transfer exited with code $EXIT_CODE" | tee -a "$LOG_FILE"
fi
