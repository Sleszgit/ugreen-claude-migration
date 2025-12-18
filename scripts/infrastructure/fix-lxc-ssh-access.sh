#!/bin/bash
# Fix SSH access for sleszugreen user in LXC 102
# This script restores the authorized_keys file from backup

set -e

echo "=== LXC 102 SSH Access Fix Script ==="
echo "Date: $(date)"
echo ""

# Check if LXC 102 is running
echo "Step 1: Checking LXC 102 status..."
if ! pct status 102 | grep -q "running"; then
    echo "ERROR: LXC 102 is not running. Please start it first."
    exit 1
fi
echo "✓ LXC 102 is running"
echo ""

# Backup current state (if .ssh exists)
echo "Step 2: Backing up current .ssh directory..."
pct exec 102 -- bash -c 'if [ -d /home/sleszugreen/.ssh ]; then tar czf /tmp/ssh-backup-$(date +%Y%m%d_%H%M%S).tar.gz /home/sleszugreen/.ssh 2>/dev/null || true; fi'
echo "✓ Current state backed up to /tmp/"
echo ""

# Create .ssh directory if it doesn't exist
echo "Step 3: Ensuring .ssh directory exists with correct permissions..."
pct exec 102 -- mkdir -p /home/sleszugreen/.ssh
pct exec 102 -- chown sleszugreen:sleszugreen /home/sleszugreen/.ssh
pct exec 102 -- chmod 700 /home/sleszugreen/.ssh
echo "✓ .ssh directory ready"
echo ""

# Copy authorized_keys from backup (use the newer backup with both keys)
echo "Step 4: Restoring authorized_keys from backup..."
pct exec 102 -- cp /home/sleszugreen/projects/proxmox-hardening/backups/authorized_keys.backup.20251209_192918 /home/sleszugreen/.ssh/authorized_keys
echo "✓ authorized_keys restored"
echo ""

# Set correct permissions on authorized_keys
echo "Step 5: Setting correct permissions on authorized_keys..."
pct exec 102 -- chown sleszugreen:sleszugreen /home/sleszugreen/.ssh/authorized_keys
pct exec 102 -- chmod 600 /home/sleszugreen/.ssh/authorized_keys
echo "✓ Permissions set"
echo ""

# Verify the setup
echo "Step 6: Verifying setup..."
echo "--- .ssh directory permissions ---"
pct exec 102 -- ls -la /home/sleszugreen/.ssh/
echo ""
echo "--- authorized_keys content (first 100 chars of each key) ---"
pct exec 102 -- bash -c 'cat /home/sleszugreen/.ssh/authorized_keys | while read line; do echo "${line:0:100}..."; done'
echo ""

# Test SSH service
echo "Step 7: Checking SSH service status..."
pct exec 102 -- systemctl is-active ssh >/dev/null 2>&1 && echo "✓ SSH service is running" || echo "⚠ SSH service may not be running"
echo ""

echo "=== Fix Complete! ==="
echo ""
echo "Next steps:"
echo "1. Test SSH access from your Windows machine:"
echo "   ssh -i C:\\Users\\jakub\\.ssh\\ugreen_key sleszugreen@192.168.40.81"
echo ""
echo "2. If it asks for a password, check:"
echo "   - Your private key path is correct"
echo "   - The key matches one of the public keys in authorized_keys"
echo "   - SSH service is running: pct exec 102 -- systemctl status ssh"
echo ""
echo "3. For debugging, check SSH logs:"
echo "   pct exec 102 -- tail -f /var/log/auth.log"
echo ""
