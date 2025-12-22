#!/bin/bash
# Transfer Filmy 10TB from 918 NAS volume2 to UGREEN
# Size: ~3.9TB

LOG_FILE="/root/nas-transfer-logs/filmy10tb-$(date +%Y%m%d-%H%M%S).log"
SOURCE="nas918:/volume2/Filmy\ 10TB/"
DEST="/storage/Media/Movies918/"

echo "=== Starting Filmy 10TB Transfer ===" | tee -a "$LOG_FILE"
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
    echo "SUCCESS: Filmy 10TB transfer completed successfully!" | tee -a "$LOG_FILE"
else
    echo "ERROR: Transfer exited with code $EXIT_CODE" | tee -a "$LOG_FILE"
fi
