#!/bin/bash
# Start backupstomove transfer in a screen session

SCREEN_NAME="backupstomove-transfer"
SCRIPT_PATH="/home/sleszugreen/nas-transfer/copy-backupstomove.sh"

# Check if screen session already exists
if screen -list | grep -q "$SCREEN_NAME"; then
    echo "⚠️  Screen session '$SCREEN_NAME' already exists!"
    echo ""
    echo "Options:"
    echo "1. Resume existing session: screen -r $SCREEN_NAME"
    echo "2. Kill existing session: screen -X -S $SCREEN_NAME quit"
    echo "3. Use a different name"
    exit 1
fi

# Pre-flight checks
echo "Pre-flight checks..."
echo ""

# Check if volume2 is mounted
if [ ! -d "/mnt/918-volume2/Filmy 10TB/backupstomove" ]; then
    echo "❌ Volume2 not mounted or backupstomove folder not found"
    echo "Run: bash /home/sleszugreen/nas-transfer/mount-volume2.sh"
    exit 1
fi
echo "✅ Source mounted and accessible"

# Check if compressed dataset exists
if [ ! -d "/storage/Media/20251209backupsfrom918" ]; then
    echo "❌ Compressed destination not found"
    echo "Run: bash /home/sleszugreen/nas-transfer/setup-compressed-backup.sh"
    exit 1
fi
echo "✅ Compressed destination ready"

# Check available space
AVAILABLE=$(df -BG /storage/Media/20251209backupsfrom918 | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE" -lt 4000 ]; then
    echo "⚠️  WARNING: Only ${AVAILABLE}GB available (need ~3800GB)"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo "✅ Sufficient space available"

echo ""
echo "=========================================="
echo "  Starting backupstomove Transfer"
echo "=========================================="
echo "Source: /mnt/918-volume2/Filmy 10TB/backupstomove/"
echo "Destination: /storage/Media/20251209backupsfrom918/"
echo "Note: Individual folders will be copied directly (no backupstomove subfolder)"
echo "Size: 3.8 TB (63,242 files)"
echo "Compression: LZ4 (ZFS)"
echo "Estimated time: 8-12 hours"
echo ""
echo "Screen session: $SCREEN_NAME"
echo "Commands:"
echo "  - Resume: screen -r $SCREEN_NAME"
echo "  - Detach: Ctrl+A then D"
echo "  - List: screen -ls"
echo ""
read -p "Press Enter to start transfer in background..."

# Start screen session
screen -dmS "$SCREEN_NAME" bash "$SCRIPT_PATH"

echo ""
echo "✅ Transfer started in background!"
echo ""
echo "To monitor progress:"
echo "  screen -r $SCREEN_NAME"
echo ""
echo "To detach (leave running):"
echo "  Press Ctrl+A, then press D"
echo ""
echo "To check if still running:"
echo "  screen -ls"
echo ""
