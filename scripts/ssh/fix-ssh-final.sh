#!/bin/bash
# Fix SSH key - FINAL working version

echo "=== Fixing SSH key authentication ==="

# Create directory
mkdir -p /home/sleszugreen/.ssh
chmod 700 /home/sleszugreen/.ssh

# Add key using printf to avoid line breaks
printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMv5ZdKSB8NrjRa04LAK1ePTpnnApTyC44RCxoJSp1a+ desktop-ugreen-nas\n' > /home/sleszugreen/.ssh/authorized_keys

# Set permissions
chmod 600 /home/sleszugreen/.ssh/authorized_keys
chown -R sleszugreen:sleszugreen /home/sleszugreen/.ssh

# Enable public key auth in SSH config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart sshd

echo ""
echo "=== Verification ==="
echo "authorized_keys content (should be ONE line):"
cat /home/sleszugreen/.ssh/authorized_keys
echo ""
echo "Line count (should be 1):"
wc -l /home/sleszugreen/.ssh/authorized_keys
echo ""
echo "Permissions:"
ls -la /home/sleszugreen/.ssh/authorized_keys
echo ""
echo "SSH config:"
grep -E '^PubkeyAuthentication' /etc/ssh/sshd_config
echo ""
echo "=== DONE ==="
echo "Test from Windows: ssh -i C:\Users\jakub\.ssh\id_ed25519_ugreen sleszugreen@192.168.40.60"
