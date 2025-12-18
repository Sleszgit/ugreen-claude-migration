#!/bin/bash
# Script to diagnose and fix LXC 102 SSH connectivity issue

echo "=== Checking LXC 102 status ==="
pct status 102

echo -e "\n=== Checking LXC 102 configuration ==="
cat /etc/pve/lxc/102.conf

echo -e "\n=== Checking if bind mount syntax is correct ==="
grep "mp0:" /etc/pve/lxc/102.conf

echo -e "\n=== Checking if mount point exists on host ==="
ls -la /root/proxmox-hardening-source/

echo -e "\n=== Checking LXC network from host ==="
pct exec 102 -- ip addr show

echo -e "\n=== Testing SSH connectivity from host ==="
timeout 3 nc -zv 192.168.40.81 22 2>&1 || echo "Cannot connect to SSH port"

echo -e "\n=== Checking for LXC startup errors ==="
journalctl -u pve-container@102 -n 50 --no-pager
