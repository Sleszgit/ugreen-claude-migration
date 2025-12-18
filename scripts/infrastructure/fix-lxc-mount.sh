#!/bin/bash
# Script to fix LXC 102 bind mount configuration

set -e

echo "=== Stopping LXC 102 ==="
pct stop 102
sleep 3

echo -e "\n=== Backing up current config ==="
cp /etc/pve/lxc/102.conf /etc/pve/lxc/102.conf.backup-$(date +%Y%m%d-%H%M%S)

echo -e "\n=== Removing incorrect mount point line ==="
# Remove any existing mp0 lines that might be malformed
sed -i '/^mp0:/d' /etc/pve/lxc/102.conf

echo -e "\n=== Ensuring mount point exists on host ==="
mkdir -p /root/proxmox-hardening-source

echo -e "\n=== Creating mount point directory inside LXC ==="
# We need to temporarily start the LXC to create the directory
pct start 102
sleep 5
pct exec 102 -- mkdir -p /home/sleszugreen/projects/proxmox-hardening
pct exec 102 -- chown sleszugreen:sleszugreen /home/sleszugreen/projects/proxmox-hardening
pct stop 102
sleep 3

echo -e "\n=== Adding correct bind mount to config ==="
# Add the mount point with correct syntax
cat >> /etc/pve/lxc/102.conf << 'EOF'
mp0: /root/proxmox-hardening-source,mp=/home/sleszugreen/projects/proxmox-hardening
EOF

echo -e "\n=== Current configuration ==="
cat /etc/pve/lxc/102.conf

echo -e "\n=== Starting LXC 102 ==="
pct start 102
sleep 5

echo -e "\n=== Verifying mount inside LXC ==="
pct exec 102 -- mount | grep proxmox-hardening

echo -e "\n=== Verifying SSH is running ==="
pct exec 102 -- systemctl status ssh --no-pager

echo -e "\n=== Testing SSH connectivity ==="
pct exec 102 -- ip addr show eth0
timeout 5 nc -zv 192.168.40.81 22 || echo "SSH test failed"

echo -e "\n=== Done! ==="
echo "Try connecting via SSH now: ssh sleszugreen@192.168.40.81"
