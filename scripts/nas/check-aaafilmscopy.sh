#!/bin/bash
# Quick check if aaafilmscopy folder exists on 918
# Run as root: sudo bash check-aaafilmscopy.sh

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo"
    exit 1
fi

echo "Checking for aaafilmscopy on 918 NAS..."
echo ""

# Create and mount if needed
MOUNT_POINT="/mnt/918-14tb"
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi

if ! mount | grep -q "$MOUNT_POINT"; then
    echo "Mounting 918:/volume3/14TB..."
    mount -t nfs -o ro,soft,intr 192.168.40.10:/volume3/14TB "$MOUNT_POINT" 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not mount 14tb share"
        echo "Available NFS exports on 918:"
        showmount -e 192.168.40.10 2>&1 || echo "showmount not available"
        exit 1
    fi
fi

echo "✓ Mounted: $MOUNT_POINT"
echo ""

# List contents
echo "Contents of 14tb share:"
ls -lah "$MOUNT_POINT" | head -20
echo ""

# Check for aaafilmscopy
if [ -d "$MOUNT_POINT/aaafilmscopy" ]; then
    echo "✅ FOUND: aaafilmscopy"
    echo ""
    SIZE=$(du -sh "$MOUNT_POINT/aaafilmscopy" 2>/dev/null | cut -f1)
    FILES=$(find "$MOUNT_POINT/aaafilmscopy" -type f 2>/dev/null | wc -l)
    echo "Size: $SIZE"
    echo "Files: $FILES"
    echo ""
    echo "Ready to copy! Run:"
    echo "  sudo bash /home/sleszugreen/copy-aaafilmscopy.sh"
else
    echo "❌ NOT FOUND: aaafilmscopy"
    echo ""
    echo "Please verify the folder name and share name."
fi
