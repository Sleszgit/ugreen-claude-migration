#!/bin/bash
# Transfer Series918 from 918 NAS to UGREEN
# Size: ~4.8TB

LOG_FILE="/root/nas-transfer-logs/series918-$(date +%Y%m%d-%H%M%S).log"
SOURCE="nas918:/volume1/Series918/"
DEST="/storage/Media/Series918/"

echo "=== Starting Series918 Transfer ===" | tee -a "$LOG_FILE"
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
  -e "ssh -i /root/.ssh/id_ed25519_918_backup" \
  "$SOURCE" "$DEST"

EXIT_CODE=$?

echo "" | tee -a "$LOG_FILE"
echo "=== Transfer Complete ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$LOG_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: Series918 transfer completed successfully!" | tee -a "$LOG_FILE"
else
    echo "ERROR: Transfer exited with code $EXIT_CODE" | tee -a "$LOG_FILE"
fi
