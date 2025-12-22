#!/bin/bash
# Fix SSH key authentication - FINAL VERSION

echo "=== Creating SSH directory ==="
mkdir -p /home/sleszugreen/.ssh
chmod 700 /home/sleszugreen/.ssh

echo "=== Adding SSH public key ==="
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMv5ZdKSB8NrjRa04LAK1ePTpnnApTyC44RCxoJSp1a+ desktop-ugreen-nas" > /home/sleszugreen/.ssh/authorized_keys

echo "=== Setting permissions ==="
chmod 600 /home/sleszugreen/.ssh/authorized_keys
chown -R sleszugreen:sleszugreen /home/sleszugreen/.ssh

echo ""
echo "=== Verification ==="
echo "File content (should be ONE line):"
cat /home/sleszugreen/.ssh/authorized_keys
echo ""
echo "File permissions:"
ls -la /home/sleszugreen/.ssh/authorized_keys
echo ""

echo "=== Checking SSH config ==="
grep -E "^(PubkeyAuthentication|PasswordAuthentication|PermitRootLogin)" /etc/ssh/sshd_config

echo ""
echo "=== DONE ==="
echo "Test from Windows: ssh sleszugreen@192.168.40.60"
