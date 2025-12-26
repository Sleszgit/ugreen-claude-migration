#!/bin/bash

# Transfer Seriale 2023 from 920 NAS to UGREEN
# Smart script: automatically detects and excludes already-transferred shows
# Execution: sudo bash /nvme2tb/lxc102scripts/transfer-seriale2023.sh
# Date: 26 Dec 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Seriale 2023 Transfer Script ===${NC}"
echo "Starting at: $(date)"
echo ""

# Configuration
NAS_IP="192.168.40.20"
NAS_SOURCE="/volume1/Seriale 2023"
NAS_MOUNT_PATH="/mnt/920-nfs-seriale"
UGREEN_TARGET="/seriale2023"
TEMP_DIR="/tmp/seriale2023-transfer"
LOG_FILE="/var/log/seriale2023-transfer.log"

# Create temp directory
mkdir -p "$TEMP_DIR"
mkdir -p "/var/log"

echo "[$(date)] Transfer started" >> "$LOG_FILE"

# Step 1: Detect series920 location on UGREEN
echo -e "${BLUE}[STEP 1]${NC} Detecting series920 folder location on UGREEN..."

SERIES920_PATH=""
if [ -d "$UGREEN_TARGET/series920" ]; then
    SERIES920_PATH="$UGREEN_TARGET/series920"
    echo -e "${GREEN}✓ Found: $SERIES920_PATH${NC}"
elif [ -d "/storage/series920" ]; then
    SERIES920_PATH="/storage/series920"
    echo -e "${GREEN}✓ Found: $SERIES920_PATH${NC}"
else
    echo -e "${YELLOW}⚠ series920 folder not found in either location${NC}"
    echo "    Checking available paths:"
    echo "    - $UGREEN_TARGET exists: $([ -d "$UGREEN_TARGET" ] && echo 'YES' || echo 'NO')"
    echo "    - /storage exists: $([ -d "/storage" ] && echo 'YES' || echo 'NO')"
    SERIES920_PATH="$UGREEN_TARGET/series920"
    echo "    Using default target: $SERIES920_PATH"
fi

# Step 2: Mount 920 NAS
echo ""
echo -e "${BLUE}[STEP 2]${NC} Mounting 920 NAS volume1 via NFS..."

if mountpoint -q "$NAS_MOUNT_PATH"; then
    echo -e "${YELLOW}⚠ Already mounted at $NAS_MOUNT_PATH${NC}"
else
    mkdir -p "$NAS_MOUNT_PATH"
    if mount -t nfs "$NAS_IP:$NAS_SOURCE" "$NAS_MOUNT_PATH"; then
        echo -e "${GREEN}✓ Mounted successfully${NC}"
    else
        echo -e "${RED}✗ Mount failed!${NC}"
        exit 1
    fi
fi

# Verify mount
if [ -d "$NAS_MOUNT_PATH" ]; then
    NAS_FOLDERS=$(ls -1 "$NAS_MOUNT_PATH" | wc -l)
    echo "  Folders in 920 NAS: $NAS_FOLDERS"
else
    echo -e "${RED}✗ Mount verification failed${NC}"
    exit 1
fi

# Step 3: Get folder lists
echo ""
echo -e "${BLUE}[STEP 3]${NC} Comparing folder lists..."

# Get folders from 920 NAS
echo "  Reading 920 NAS folders..."
ls -1 "$NAS_MOUNT_PATH" > "$TEMP_DIR/nas920-folders.txt"
echo "  Total folders on 920: $(wc -l < "$TEMP_DIR/nas920-folders.txt")"

# Get folders from UGREEN (if series920 exists)
if [ -d "$SERIES920_PATH" ]; then
    echo "  Reading UGREEN series920 folders..."
    ls -1 "$SERIES920_PATH" > "$TEMP_DIR/ugreen-folders.txt" 2>/dev/null || true
    UGREEN_COUNT=$(wc -l < "$TEMP_DIR/ugreen-folders.txt")
    echo "  Total folders on UGREEN: $UGREEN_COUNT"
else
    echo "  UGREEN series920 doesn't exist yet (first transfer)"
    > "$TEMP_DIR/ugreen-folders.txt"
    echo "  Total folders on UGREEN: 0"
fi

# Step 4: Generate exclude list
echo ""
echo -e "${BLUE}[STEP 4]${NC} Generating exclude list..."

# Create exclude file with folders that already exist on UGREEN
> "$TEMP_DIR/rsync-exclude.txt"
EXCLUDE_COUNT=0

while IFS= read -r folder; do
    if grep -q "^${folder}$" "$TEMP_DIR/ugreen-folders.txt"; then
        echo "$folder" >> "$TEMP_DIR/rsync-exclude.txt"
        EXCLUDE_COUNT=$((EXCLUDE_COUNT + 1))
        echo "  Excluding: $folder (already on UGREEN)"
    fi
done < "$TEMP_DIR/nas920-folders.txt"

echo -e "${GREEN}✓ Will exclude $EXCLUDE_COUNT folders${NC}"
COPY_COUNT=$(($(wc -l < "$TEMP_DIR/nas920-folders.txt") - EXCLUDE_COUNT))
echo "  Will copy: $COPY_COUNT folders"

# Step 5: Display summary before transfer
echo ""
echo -e "${YELLOW}=== Transfer Summary ===${NC}"
echo "  Source: $NAS_IP:$NAS_SOURCE"
echo "  Target: $SERIES920_PATH"
echo "  Folders to copy: $COPY_COUNT"
echo "  Folders to skip: $EXCLUDE_COUNT"
echo ""

if [ $COPY_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All folders already transferred!${NC}"
    echo "  No transfer needed."
else
    echo -e "${YELLOW}Ready to transfer $COPY_COUNT folders${NC}"
    echo ""
    echo "Review the plan above. To proceed with the transfer:"
    echo "  1. Check the excluded folders list below"
    echo "  2. Run: sudo rsync -av --exclude-from='$TEMP_DIR/rsync-exclude.txt' '$NAS_MOUNT_PATH/' '$SERIES920_PATH/'"
    echo ""
    echo "Folders that will be EXCLUDED (already on UGREEN):"
    if [ -s "$TEMP_DIR/rsync-exclude.txt" ]; then
        cat "$TEMP_DIR/rsync-exclude.txt" | sed 's/^/    - /'
    else
        echo "    (none)"
    fi
    echo ""
    echo "Folders that will be COPIED from 920 NAS:"
    grep -v -f "$TEMP_DIR/ugreen-folders.txt" "$TEMP_DIR/nas920-folders.txt" | sed 's/^/    + /' || true
fi

echo ""
echo "[$(date)] Analysis complete" >> "$LOG_FILE"
echo "Temp files saved in: $TEMP_DIR"
echo "Log file: $LOG_FILE"

