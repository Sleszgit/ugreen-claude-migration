#!/bin/bash

# Fix NFS exports on Homelab: Change root from read-only to read-write
# This enables NFSv4 mounting of /mnt/homelab-backups/lxc102-vzdump

HOMELAB_IP="192.168.40.40"
HOMELAB_USER="ugreen-homelab-ssh"

echo "🔧 Fixing NFS exports on Homelab..."
echo "Target: $HOMELAB_IP"
echo ""

# Step 1: Backup /etc/exports
echo "📋 Step 1: Backing up /etc/exports..."
ssh "$HOMELAB_USER@$HOMELAB_IP" "sudo cp /etc/exports /etc/exports.backup.$(date +%s)" && echo "✅ Backup created" || { echo "❌ Backup failed"; exit 1; }

echo ""

# Step 2: Edit /etc/exports - change ro to rw for root export
echo "📝 Step 2: Updating /etc/exports..."
ssh "$HOMELAB_USER@$HOMELAB_IP" << 'REMOTE_SCRIPT'
sudo sed -i 's|/mnt/homelab-backups 192.168.40.60(ro,|/mnt/homelab-backups 192.168.40.60(rw,|' /etc/exports
echo "✅ Root export changed from ro to rw"
REMOTE_SCRIPT

echo ""

# Step 3: Reload exports
echo "🔄 Step 3: Reloading NFS exports..."
ssh "$HOMELAB_USER@$HOMELAB_IP" "sudo exportfs -ra" && echo "✅ Exports reloaded" || { echo "❌ Reload failed"; exit 1; }

echo ""

# Step 4: Verify the change
echo "✓ Step 4: Verifying configuration..."
ssh "$HOMELAB_USER@$HOMELAB_IP" "cat /etc/exports | grep homelab"

echo ""
echo "✅ NFS exports fixed!"
echo ""
echo "📌 Next step: Try mounting again in Proxmox web UI"
echo "   Datacenter → Storage → Add NFS"
echo ""
