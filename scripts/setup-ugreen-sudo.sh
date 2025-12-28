#!/bin/bash

# Setup passwordless sudo for ugreen-homelab-ssh user on homelab
# Run this on the homelab as root
# Created: 28 Dec 2025

set -e

echo "🔧 Setting up passwordless sudo for ugreen-homelab-ssh..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "❌ This script must be run as root"
   exit 1
fi

# Create sudoers.d entry for ugreen-homelab-ssh with Proxmox commands
echo "📝 Adding sudoers configuration for Proxmox commands..."
cat > /etc/sudoers.d/ugreen-homelab-ssh << 'EOF'
# Allow ugreen-homelab-ssh to run Proxmox management commands without password
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/qm, /usr/bin/pct, /usr/local/bin/pvesh, /usr/sbin/pveum, /sbin/zpool, /sbin/zfs, /bin/systemctl, /sbin/pve-firewall, /usr/bin/systemctl
EOF

chmod 0440 /etc/sudoers.d/ugreen-homelab-ssh
echo "✅ Sudoers configuration created"
echo ""

# Verify it was created correctly
echo "🔍 Verifying sudoers configuration..."
visudo -c -f /etc/sudoers.d/ugreen-homelab-ssh && echo "✅ Sudoers file is valid"
echo ""

echo "🎯 Setup complete!"
echo ""
echo "The ugreen-homelab-ssh user can now run Proxmox commands with sudo without a password:"
echo "  - qm (VM management)"
echo "  - pct (Container management)"
echo "  - pvesh (Proxmox API CLI)"
echo "  - pveum (User/permission management)"
echo "  - zpool (ZFS pool management)"
echo "  - zfs (ZFS filesystem management)"
echo "  - systemctl (Service management)"
