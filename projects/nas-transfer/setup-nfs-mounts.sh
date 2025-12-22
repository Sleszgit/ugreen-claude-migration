#!/bin/bash
# Setup NFS mounts for 918 NAS to UGREEN transfer
# Run this on Proxmox host (192.168.40.60) as root

set -e  # Exit on error

echo "=== NFS Mount Setup for 918 to UGREEN Transfer ==="
echo "Started: $(date)"
echo ""

# Step 1: Install NFS client tools
echo "[1/5] Installing NFS client tools..."
apt update
apt install -y nfs-common
echo "✓ NFS client installed"
echo ""

# Step 2: Create mount points
echo "[2/5] Creating mount points..."
mkdir -p /mnt/918-filmy918
mkdir -p /mnt/918-series918
echo "✓ Mount points created:"
echo "  - /mnt/918-filmy918"
echo "  - /mnt/918-series918"
echo ""

# Step 3: Test NFS connection
echo "[3/5] Testing NFS availability from 918 NAS..."
showmount -e 192.168.40.10 || {
    echo "❌ ERROR: Cannot see NFS exports from 918 NAS"
    echo "Please check:"
    echo "  1. NFS service is enabled on Synology DSM"
    echo "  2. Folders are shared via NFS"
    echo "  3. IP 192.168.40.60 is allowed in NFS permissions"
    exit 1
}
echo "✓ NFS exports visible from 918 NAS"
echo ""

# Step 4: Mount NFS shares
echo "[4/5] Mounting NFS shares..."
echo "Mounting /volume1/Filmy918..."
mount -t nfs -o ro,soft,intr 192.168.40.10:/volume1/Filmy918 /mnt/918-filmy918
echo "✓ Mounted: /mnt/918-filmy918"

echo "Mounting /volume1/Series918..."
mount -t nfs -o ro,soft,intr 192.168.40.10:/volume1/Series918 /mnt/918-series918
echo "✓ Mounted: /mnt/918-series918"
echo ""

# Step 5: Verify mounts
echo "[5/5] Verifying mounts..."
if mount | grep -q "918-filmy918"; then
    echo "✓ /mnt/918-filmy918 is mounted"
    echo "  Content sample:"
    ls -lh /mnt/918-filmy918 | head -5
else
    echo "❌ ERROR: /mnt/918-filmy918 not mounted"
    exit 1
fi

echo ""
if mount | grep -q "918-series918"; then
    echo "✓ /mnt/918-series918 is mounted"
    echo "  Content sample:"
    ls -lh /mnt/918-series918 | head -5
else
    echo "❌ ERROR: /mnt/918-series918 not mounted"
    exit 1
fi

echo ""
echo "=== SUCCESS ==="
echo "NFS mounts are ready!"
echo ""
echo "Mounted directories:"
echo "  /mnt/918-filmy918   → /volume1/Filmy918 (918 NAS)"
echo "  /mnt/918-series918  → /volume1/Series918 (918 NAS)"
echo ""
echo "Next step: Run transfer scripts"
echo "Completed: $(date)"
