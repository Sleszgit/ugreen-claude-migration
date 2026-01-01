#!/bin/bash

# Fix malformed /etc/pve/firewall/cluster.fw on homelab Proxmox
# Created: 28 Dec 2025
# Purpose: Replace EOF-corrupted firewall config with corrected version

set -e

REMOTE_HOST="192.168.40.40"
REMOTE_USER="sshadmin"
BACKUP_DIR="/root/firewall-backups"
BACKUP_FILE="cluster.fw.backup-$(date +%Y%m%d-%H%M%S)"

echo "🔧 Starting homelab firewall configuration fix..."
echo ""

# Create backup on remote host
echo "📦 Creating backup on homelab..."
ssh -tt "$REMOTE_USER@$REMOTE_HOST" "sudo mkdir -p $BACKUP_DIR && sudo cp /etc/pve/firewall/cluster.fw $BACKUP_DIR/$BACKUP_FILE && echo 'Backup created: $BACKUP_FILE'"

# Show what we're about to write
echo ""
echo "📝 Writing corrected firewall configuration..."
echo ""

# Write corrected config via SSH
ssh -t "$REMOTE_USER@$REMOTE_HOST" "sudo tee /etc/pve/firewall/cluster.fw" > /dev/null << 'FIREWALL_EOF'
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
FIREWALL_EOF

echo "✅ Configuration written successfully"
echo ""

# Verify the file was written correctly
echo "🔍 Verifying configuration..."
echo ""
ssh -t "$REMOTE_USER@$REMOTE_HOST" "echo '--- Firewall config structure ---' && sudo head -30 /etc/pve/firewall/cluster.fw && echo '...' && sudo tail -5 /etc/pve/firewall/cluster.fw"
echo ""

# Restart firewall
echo "🔄 Restarting pve-firewall service..."
ssh -t "$REMOTE_USER@$REMOTE_HOST" "sudo systemctl restart pve-firewall" && echo "✅ pve-firewall restarted"
echo ""

# Wait for firewall to stabilize
sleep 2

# Test SSH connectivity from UGREEN LXC 102 to homelab
echo "🧪 Testing SSH connectivity from UGREEN LXC 102 to homelab..."
timeout 5 ssh -o ConnectTimeout=3 "sshadmin@192.168.40.40" "echo '✅ SSH connection from UGREEN test successful'" || echo "❌ SSH test failed - firewall may still need adjustment"
echo ""

echo "🎯 Firewall fix attempt completed!"
echo "   Backup location: $BACKUP_DIR/$BACKUP_FILE"
echo "   If issues occur, restore with: sudo cp $BACKUP_DIR/$BACKUP_FILE /etc/pve/firewall/cluster.fw && sudo systemctl restart pve-firewall"
