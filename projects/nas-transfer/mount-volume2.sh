#!/bin/bash
# Mount volume2 from 918 NAS to access Filmy 10TB

echo "Mounting volume2 from 918 NAS..."

# Create mount point
sudo mkdir -p /mnt/918-volume2

# Mount volume2 (read-only, NFSv4)
sudo mount -t nfs -o ro,vers=4 192.168.40.10:/volume2 /mnt/918-volume2

if [ $? -eq 0 ]; then
    echo "✅ Volume2 mounted successfully at /mnt/918-volume2"
    echo ""
    echo "Checking for backupstomove folder..."
    ls -lh /mnt/918-volume2/
else
    echo "❌ Failed to mount volume2"
    exit 1
fi
