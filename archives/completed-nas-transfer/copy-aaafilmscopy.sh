#!/bin/bash
# Copy aaafilmscopy from 918 14tb share to UGREEN Movies918/Misc
# Run as root: sudo bash copy-aaafilmscopy.sh

set -e

echo "========================================="
echo "Copy aaafilmscopy to UGREEN"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo:"
    echo "  sudo bash copy-aaafilmscopy.sh"
    exit 1
fi

# Create mount point for 14tb share
MOUNT_POINT="/mnt/918-14tb"
echo "[1] Setting up NFS mount for 14tb share..."
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
    echo "✓ Created mount point: $MOUNT_POINT"
else
    echo "✓ Mount point exists: $MOUNT_POINT"
fi

# Mount the 14tb share from 918 NAS
if ! mount | grep -q "$MOUNT_POINT"; then
    echo "Mounting 918:/volume3/14TB..."
    mount -t nfs -o ro,soft,intr 192.168.40.10:/volume3/14TB "$MOUNT_POINT"
    echo "✓ NFS mounted successfully"
else
    echo "✓ Already mounted"
fi
echo ""

# Check if source folder exists
SOURCE="$MOUNT_POINT/aaafilmscopy"
echo "[2] Checking source folder..."
if [ ! -d "$SOURCE" ]; then
    echo "ERROR: Source folder not found: $SOURCE"
    echo "Available folders in 14tb:"
    ls -la "$MOUNT_POINT" | head -20
    exit 1
fi
echo "✓ Source folder exists: $SOURCE"

# Get source folder size
echo "Calculating size (this may take a moment)..."
SIZE=$(du -sh "$SOURCE" 2>/dev/null | cut -f1)
echo "✓ Source folder size: $SIZE"
echo ""

# Create destination folder
DEST="/storage/Media/Movies918/Misc"
echo "[3] Creating destination folder..."
if [ ! -d "$DEST" ]; then
    mkdir -p "$DEST"
    echo "✓ Created: $DEST"
else
    echo "✓ Destination exists: $DEST"
fi

# Set ownership
chown sleszugreen:sleszugreen "$DEST"
echo "✓ Set ownership to sleszugreen"
echo ""

# Start the copy
echo "[4] Starting copy operation..."
echo "Source: $SOURCE"
echo "Destination: $DEST/aaafilmscopy/"
echo "Size: $SIZE"
echo ""
echo "This will take some time depending on the size..."
echo ""

# Use rsync for reliable copying with progress
rsync -avh \
  --progress \
  --partial \
  --append-verify \
  --stats \
  "$SOURCE/" "$DEST/aaafilmscopy/"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "========================================="
    echo "✅ COPY COMPLETE!"
    echo "========================================="
    echo ""
    echo "Copied: $SIZE"
    echo "From: 918:/volume3/14TB/aaafilmscopy"
    echo "To: /storage/Media/Movies918/Misc/aaafilmscopy/"
    echo ""
    echo "Verify:"
    echo "  du -sh $DEST/aaafilmscopy"
    echo ""
else
    echo "========================================="
    echo "❌ COPY FAILED!"
    echo "========================================="
    echo "Exit code: $EXIT_CODE"
    echo ""
fi

# Ask if should unmount
echo "Do you want to unmount the 14tb share? (y/n)"
read -r UNMOUNT
if [[ "$UNMOUNT" =~ ^[Yy]$ ]]; then
    umount "$MOUNT_POINT"
    echo "✓ Unmounted $MOUNT_POINT"
else
    echo "✓ Keeping mount active at: $MOUNT_POINT"
fi
