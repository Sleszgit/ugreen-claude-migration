#!/bin/bash
# Transfer movie folders 2018, 2022, 2023 from 918 NAS to UGREEN
# Source: /volume1/Filmy918/{2018,2022,2023}
# Destination: /storage/Media/Movies918/

LOG_FILE="/root/nas-transfer-logs/movies-$(date +%Y%m%d-%H%M%S).log"
DEST="/storage/Media/Movies918/"

echo "=== Starting Movies Transfer (2018, 2022, 2023) ===" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Destination: $DEST" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Transfer 2018 folder
echo ">>> Transferring 2018 folder..." | tee -a "$LOG_FILE"
rsync -avh \
  --progress \
  --partial \
  --append-verify \
  --stats \
  --log-file="$LOG_FILE" \
  nas918:/volume1/Filmy918/2018/ \
  "$DEST/2018/"

# Transfer 2022 folder
echo "" | tee -a "$LOG_FILE"
echo ">>> Transferring 2022 folder..." | tee -a "$LOG_FILE"
rsync -avh \
  --progress \
  --partial \
  --append-verify \
  --stats \
  --log-file="$LOG_FILE" \
  nas918:/volume1/Filmy918/2022/ \
  "$DEST/2022/"

# Transfer 2023 folder
echo "" | tee -a "$LOG_FILE"
echo ">>> Transferring 2023 folder..." | tee -a "$LOG_FILE"
rsync -avh \
  --progress \
  --partial \
  --append-verify \
  --stats \
  --log-file="$LOG_FILE" \
  nas918:/volume1/Filmy918/2023/ \
  "$DEST/2023/"

EXIT_CODE=$?

echo "" | tee -a "$LOG_FILE"
echo "=== Transfer Complete ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$LOG_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: Movies transfer completed successfully!" | tee -a "$LOG_FILE"
else
    echo "ERROR: Transfer exited with code $EXIT_CODE" | tee -a "$LOG_FILE"
fi
