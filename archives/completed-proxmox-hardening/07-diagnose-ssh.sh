#!/bin/bash
# Diagnose SSH key authentication issue

echo "=== SSH Key Authentication Diagnostics ==="
echo ""

echo "1. Home directory permissions:"
ls -ld /home/sleszugreen
echo ""

echo "2. .ssh directory permissions:"
ls -ld /home/sleszugreen/.ssh
echo ""

echo "3. authorized_keys file:"
ls -l /home/sleszugreen/.ssh/authorized_keys
echo ""

echo "4. authorized_keys content:"
cat /home/sleszugreen/.ssh/authorized_keys
echo ""

echo "5. SSH daemon config:"
grep -E '^(PubkeyAuthentication|AuthorizedKeysFile|PermitRootLogin|PasswordAuthentication)' /etc/ssh/sshd_config
echo ""

echo "6. Check for RestrictedMode or other blocks:"
grep -i "match user sleszugreen" /etc/ssh/sshd_config
echo ""

echo "7. SELinux status:"
getenforce 2>/dev/null || echo "SELinux not installed"
echo ""

echo "8. Test SSH key from localhost:"
su - sleszugreen -c "ssh-keygen -lf ~/.ssh/authorized_keys"
echo ""

echo "9. Recent auth attempts:"
tail -20 /var/log/auth.log | grep -i "sleszugreen\|publickey"
echo ""

echo "=== END DIAGNOSTICS ==="
