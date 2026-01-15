#!/usr/bin/env bash
set -Eeuo pipefail

# Error trap
trap 'echo "ERROR on line $LINENO, exit code $?"' ERR

REMOTE_HOST="homelab"
SMB_CONF="/etc/samba/smb.conf"
BACKUP_SUFFIX=$(date +%Y%m%d-%H%M%S)

echo "[*] Connecting to Homelab (homelab alias)..."

# Step 1: Create timestamped backup
echo "[*] Creating timestamped backup of $SMB_CONF..."
ssh -o ConnectTimeout=10 "${REMOTE_HOST}" \
  "sudo cp ${SMB_CONF} ${SMB_CONF}.bak.${BACKUP_SUFFIX}" && \
  echo "    ✓ Backup saved to: ${SMB_CONF}.bak.${BACKUP_SUFFIX}"

# Step 2: Create a Python script on remote to edit the config (safer than sed for complex INI)
echo "[*] Applying configuration updates..."

ssh -o ConnectTimeout=10 "${REMOTE_HOST}" \
  sudo python3 << 'EOPY'
import re
import os
import shutil

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

# Step 3: Validate Samba configuration
echo "[*] Validating Samba configuration..."
ssh -o ConnectTimeout=10 "${REMOTE_HOST}" \
  "sudo testparm -v ${SMB_CONF}" > /dev/null && \
  echo "    ✓ Configuration is valid"

# Step 4: Restart services
echo "[*] Restarting smbd and nmbd services..."
ssh -o ConnectTimeout=10 "${REMOTE_HOST}" \
  "sudo systemctl restart smbd nmbd" && \
  echo "    ✓ Services restarted successfully"

echo ""
echo "============================================"
echo "✓ SAMBA CONFIGURATION FIX COMPLETE"
echo "============================================"
echo "Backup location: ${SMB_CONF}.bak.${BACKUP_SUFFIX}"
echo "Updated shares:"
echo "  • [FilmsHomelab]  → forced to samba-homelab user"
echo "  • [SeriesHomelab] → forced to samba-homelab user"
echo ""
echo "Windows clients should now be able to access both shares."
echo "Test with: \\\\192.168.40.40\\FilmsHomelab"
