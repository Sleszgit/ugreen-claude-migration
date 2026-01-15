#!/usr/bin/env bash
set -Eeuo pipefail

# Error trap
trap 'echo "ERROR on line $LINENO, exit code $?"' ERR

echo "=========================================="
echo "Homelab Samba Share Fix - Local Execution"
echo "=========================================="
echo ""

SMB_CONF="/etc/samba/smb.conf"
BACKUP_SUFFIX=$(date +%Y%m%d-%H%M%S)

# Step 1: Create backup
echo "[1/4] Creating timestamped backup..."
sudo cp "${SMB_CONF}" "${SMB_CONF}.bak.${BACKUP_SUFFIX}"
echo "  ✓ Backup saved to: ${SMB_CONF}.bak.${BACKUP_SUFFIX}"
echo ""

# Step 2: Apply Python fixes
echo "[2/4] Applying Python fixes to Samba configuration..."
sudo python3 << 'EOPY'
import re
import os

SMB_CONF = "/etc/samba/smb.conf"

# Read current config
with open(SMB_CONF, 'r') as f:
    content = f.read()

# Remove old [FilmsHomelab] section (from [FilmsHomelab] to just before next [SectionName])
content = re.sub(
    r'\[FilmsHomelab\].*?(?=\n\[|\Z)',
    '',
    content,
    flags=re.DOTALL
)

# Remove old [SeriesHomelab] section
content = re.sub(
    r'\[SeriesHomelab\].*?(?=\n\[|\Z)',
    '',
    content,
    flags=re.DOTALL
)

# Clean up excess blank lines (more than 2 consecutive newlines)
content = re.sub(r'\n\n\n+', '\n\n', content)

# Ensure file ends with single newline
content = content.rstrip() + '\n'

# Append corrected share blocks
corrected_shares = '''
# Films Collection
[FilmsHomelab]
   comment = Films Collection
   path = /Seagate-20TB-mirror/FilmsHomelab
   browseable = yes
   read only = no
   valid users = samba-homelab
   force user = samba-homelab
   force group = samba-homelab
   create mask = 0664
   directory mask = 0775

# Series Collection
[SeriesHomelab]
   comment = Series Collection
   path = /Seagate-20TB-mirror/SeriesHomelab
   browseable = yes
   read only = no
   valid users = samba-homelab
   force user = samba-homelab
   force group = samba-homelab
   create mask = 0664
   directory mask = 0775
'''

content = content + corrected_shares + '\n'

# Write updated config
with open(SMB_CONF, 'w') as f:
    f.write(content)

print("[✓] Configuration blocks updated")
EOPY

echo "  ✓ Configuration fixed"
echo ""

# Step 3: Validate
echo "[3/4] Validating Samba configuration..."
sudo testparm -s "${SMB_CONF}" > /dev/null
echo "  ✓ Configuration is valid"
echo ""

# Step 4: Restart services
echo "[4/4] Restarting smbd and nmbd services..."
sudo systemctl restart smbd nmbd
echo "  ✓ Services restarted successfully"
echo ""

echo "=========================================="
echo "✓ SAMBA CONFIGURATION FIX COMPLETE"
echo "=========================================="
echo ""
echo "Backup location: ${SMB_CONF}.bak.${BACKUP_SUFFIX}"
echo "Updated shares:"
echo "  • [FilmsHomelab]  → /Seagate-20TB-mirror/FilmsHomelab"
echo "  • [SeriesHomelab] → /Seagate-20TB-mirror/SeriesHomelab"
echo "  Both forced to samba-homelab user"
echo ""
echo "Windows clients should now be able to access both shares."
echo "Test with: \\\\192.168.40.40\\FilmsHomelab"
