#!/bin/bash
# Create compressed ZFS dataset for backupstomove

echo "Creating compressed ZFS dataset for backups from 918..."

# Create a new ZFS dataset with LZ4 compression
sudo zfs create -o compression=lz4 storage/Media/20251209backupsfrom918

if [ $? -eq 0 ]; then
    echo "✅ Compressed dataset created at /storage/Media/20251209backupsfrom918"
    echo ""

    # Verify compression is enabled
    echo "Checking compression settings:"
    sudo zfs get compression storage/Media/20251209backupsfrom918

    echo ""
    echo "Available space:"
    df -h /storage/Media/20251209backupsfrom918

    echo ""
    echo "✅ Ready to copy backupstomove to /storage/Media/20251209backupsfrom918/"
else
    echo "❌ Failed to create compressed dataset"
    exit 1
fi
