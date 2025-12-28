#!/bin/bash

# Fix malformed /etc/pve/firewall/cluster.fw on homelab Proxmox
# Run this script DIRECTLY on the homelab machine
# Created: 28 Dec 2025

set -e

BACKUP_DIR="/root/firewall-backups"
BACKUP_FILE="cluster.fw.backup-$(date +%Y%m%d-%H%M%S)"

echo "🔧 Starting homelab firewall configuration fix..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "❌ This script must be run as root (use: sudo ./fix-homelab-firewall-local.sh)"
   exit 1
fi

# Create backup
echo "📦 Creating backup..."
mkdir -p $BACKUP_DIR
cp /etc/pve/firewall/cluster.fw $BACKUP_DIR/$BACKUP_FILE
echo "✅ Backup created: $BACKUP_DIR/$BACKUP_FILE"
echo ""

# Write corrected config
echo "📝 Writing corrected firewall configuration..."
cat > /etc/pve/firewall/cluster.fw << 'EOF'
[OPTIONS]
policy_out: ACCEPT
enable: 1
policy_in: DROP

[IPSET management]
100.64.0.0/10 # Tailscale network
192.168.40.0/24 # Proxmox local VLAN
192.168.99.0/24 # Desktop/Management VLAN
10.10.10.0/24 # Docker-Services VLAN

[IPSET kavita-vm]
10.10.10.10 # Ubuntu Docker-Services VM

[RULES]

# SSH - allow from management + container
IN ACCEPT -source +management -p tcp -dport 22 -log nolog # SSH from management
IN ACCEPT -source 192.168.40.82 -p tcp -dport 22 -log nolog # SSH from UGREEN LXC102

# Proxmox Web UI
IN ACCEPT -source +management -p tcp -dport 8006 -log nolog

# SPICE Proxy
IN ACCEPT -source +management -p tcp -dport 3128 -log nolog

# VNC Console
IN ACCEPT -source +management -p tcp -dport 5900:5999 -log nolog

# ICMP/Ping
IN ACCEPT -source +management -p icmp -log nolog

[group nfs-clients]

# NFS for Kavita VM
IN ACCEPT -source +kavita-vm -p udp -dport 111 -log nolog
IN ACCEPT -source +kavita-vm -p tcp -dport 111 -log nolog
IN ACCEPT -source +kavita-vm -p tcp -dport 2049 -log nolog

[group samba-backup]

# SMB/Samba ports for homelab backup access
IN ACCEPT -source 192.168.99.0/24 -p tcp -dport 135,139,445
IN ACCEPT -source 192.168.99.0/24 -p udp -dport 137,138,445
EOF

echo "✅ Configuration written successfully"
echo ""

# Verify the file
echo "🔍 Verifying configuration..."
echo "--- First 30 lines ---"
head -30 /etc/pve/firewall/cluster.fw
echo ""
echo "--- Last 5 lines ---"
tail -5 /etc/pve/firewall/cluster.fw
echo ""

# Restart firewall
echo "🔄 Restarting pve-firewall service..."
systemctl restart pve-firewall
echo "✅ pve-firewall restarted"
echo ""

# Wait for firewall to stabilize
sleep 2

echo "🎯 Firewall fix completed!"
echo ""
echo "📋 Summary:"
echo "   ✅ Backup location: $BACKUP_DIR/$BACKUP_FILE"
echo "   ✅ Configuration fixed"
echo "   ✅ Firewall service restarted"
echo ""
echo "Next: Test SSH from UGREEN LXC102 to homelab (192.168.40.40)"
echo ""
echo "To restore if needed:"
echo "   sudo cp $BACKUP_DIR/$BACKUP_FILE /etc/pve/firewall/cluster.fw"
echo "   sudo systemctl restart pve-firewall"
