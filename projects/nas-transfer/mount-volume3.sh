#!/bin/bash
# Mount volume3 from 918 NAS to access 14TB folder
# Run this on Proxmox host (192.168.40.60) as root

echo "Mounting volume3 from 918 NAS..."

# Create mount point
mkdir -p /mnt/918-volume3

# Mount volume3 (read-only, NFSv4)
mount -t nfs -o ro,vers=4 192.168.40.10:/volume3 /mnt/918-volume3

if [ $? -eq 0 ]; then
    echo "✅ Volume3 mounted successfully at /mnt/918-volume3"
    echo ""
    echo "Checking contents..."
    ls -lh /mnt/918-volume3/
    echo ""
    echo "Checking 14TB folder..."
    ls -lh /mnt/918-volume3/14TB/
else
    echo "❌ Failed to mount volume3"
    exit 1
fi
